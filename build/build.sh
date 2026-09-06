#!/bin/bash
# ==============================================================================
# VEILOS ISO Generation Engine
# Builds a bootable Debian Bookworm based VEILOS Live Hybrid ISO
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/output"

echo "========================================================"
echo "          VEILOS ISO BUILD SYSTEM (Phase 1)             "
echo "========================================================"
echo "Root directory: ${ROOT_DIR}"
echo "Output directory: ${OUTPUT_DIR}"

# 1. Dependency checks
REQUIRED_TOOLS=(lb debootstrap xorriso mksquashfs isohybrid)
MISSING=()
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING+=("$tool")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "[!] Missing host build dependencies: ${MISSING[*]}"
    echo "    On Debian/Ubuntu, install with:"
    echo "    sudo apt-get update && sudo apt-get install -y live-build debootstrap xorriso squashfs-tools syslinux-utils"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "[!] Error: live-build requires root privileges to mount chroots and debootstrap."
    echo "    Please run with: sudo ./build/build.sh"
    exit 1
fi

# 2. Preparation
mkdir -p "${OUTPUT_DIR}"
cd "${ROOT_DIR}"

# Patch host live-build scripts to use Debian Bookworm paths (security suite & Contents layout)
echo "[*] Ensuring live-build uses modern Debian repository structure..."
if [ -d /usr/lib/live ]; then
    find /usr/lib/live -type f -exec sed -i 's|/updates|-security|g' {} + 2>/dev/null || true
    find /usr/lib/live -type f -exec sed -i 's|/dists/\([^/]*\)/Contents-|/dists/\1/main/Contents-|g' {} + 2>/dev/null || true
fi
if [ -d /usr/share/live ]; then
    find /usr/share/live -type f -exec sed -i 's|/updates|-security|g' {} + 2>/dev/null || true
    find /usr/share/live -type f -exec sed -i 's|/dists/\([^/]*\)/Contents-|/dists/\1/main/Contents-|g' {} + 2>/dev/null || true
fi

# Install smart rsvg wrapper on host
echo "[*] Installing smart rsvg compatibility wrapper on host..."
cp -f "${ROOT_DIR}/config/includes.chroot/usr/local/bin/rsvg" /usr/local/bin/rsvg 2>/dev/null || true
cp -f "${ROOT_DIR}/config/includes.chroot/usr/local/bin/rsvg" /usr/bin/rsvg 2>/dev/null || true
chmod +x /usr/local/bin/rsvg /usr/bin/rsvg 2>/dev/null || true

# Ensure executable permissions on all repository scripts
chmod +x "${ROOT_DIR}/config/includes.chroot/usr/local/bin/"* 2>/dev/null || true
chmod +x "${ROOT_DIR}/config/hooks/live/"* 2>/dev/null || true

# 3. Cross-link host Syslinux & ISOLINUX libraries
echo "[*] Setting up host Syslinux and ISOLINUX libraries..."
mkdir -p /usr/lib/ISOLINUX /usr/lib/syslinux/modules/bios /usr/lib/syslinux
cp -rn /usr/lib/ISOLINUX/* /usr/lib/syslinux/ 2>/dev/null || true
cp -rn /usr/lib/syslinux/modules/bios/* /usr/lib/ISOLINUX/ 2>/dev/null || true
cp -rn /usr/lib/syslinux/* /usr/lib/ISOLINUX/ 2>/dev/null || true
cp -rn /usr/lib/ISOLINUX/* /usr/lib/syslinux/modules/bios/ 2>/dev/null || true

# 4. Dereference host live-build bootloader templates so they contain real binaries instead of symlinks
echo "[*] Dereferencing live-build bootloader template symlinks..."
for dir in /usr/share/live/build/bootloaders/isolinux /usr/share/live/build/bootloaders/syslinux_common; do
    if [ -d "$dir" ]; then
        find "$dir" -type l | while read -r symlink; do
            target=$(readlink -f "$symlink" || true)
            if [ -n "$target" ] && [ -f "$target" ]; then
                rm -f "$symlink"
                cp -f "$target" "$symlink"
            fi
        done
    fi
done

# Copy actual binary files into live-build template directories
cp -f /usr/lib/ISOLINUX/isolinux.bin /usr/share/live/build/bootloaders/isolinux/ 2>/dev/null || true
cp -f /usr/lib/syslinux/modules/bios/* /usr/share/live/build/bootloaders/isolinux/ 2>/dev/null || true
cp -f /usr/lib/syslinux/modules/bios/* /usr/share/live/build/bootloaders/syslinux_common/ 2>/dev/null || true
cp -f /usr/lib/syslinux/* /usr/share/live/build/bootloaders/isolinux/ 2>/dev/null || true
cp -f /usr/lib/syslinux/* /usr/share/live/build/bootloaders/syslinux_common/ 2>/dev/null || true

# Pre-convert any splash.svg in template directories to splash.png to eliminate runtime SVG conversion
for f in $(find /usr/share/live/build/bootloaders -name "splash.svg" 2>/dev/null); do
    dir=$(dirname "$f")
    if command -v rsvg-convert >/dev/null 2>&1; then
        rsvg-convert --format png --width 640 --height 480 "$f" -o "$dir/splash.png" 2>/dev/null || true
    fi
    rm -f "$f"
done

# 5. Run live-build environment patcher (guards Ubuntu gfxboot bug, syncs bootloaders & templates)
if [ -f "${ROOT_DIR}/build/patch_live_build.py" ]; then
    python3 "${ROOT_DIR}/build/patch_live_build.py" || true
fi

echo "[*] Cleaning previous build artifacts..."
lb clean --purge || true

echo "[*] Initializing live-build configuration..."
mkdir -p "${ROOT_DIR}/auto"
cp -r "${ROOT_DIR}/config/auto/"* "${ROOT_DIR}/auto/" 2>/dev/null || true
chmod +x "${ROOT_DIR}/auto/"* 2>/dev/null || true
lb config

# Copy custom hooks
if [[ -d "${ROOT_DIR}/config/hooks" ]]; then
    mkdir -p "${ROOT_DIR}/config/hooks/live"
fi

# Re-verify patches right before build
if [ -f "${ROOT_DIR}/build/patch_live_build.py" ]; then
    python3 "${ROOT_DIR}/build/patch_live_build.py" || true
fi

echo "[*] Building VEILOS Live ISO (this may take 10-20 minutes depending on network)..."
lb build 2>&1 | tee "${OUTPUT_DIR}/build.log"

# Move generated ISO to output
ISO_FILE=$(ls -t "${ROOT_DIR}"/*.iso 2>/dev/null | head -n 1 || true)
if [[ -n "$ISO_FILE" && -f "$ISO_FILE" ]]; then
    mv "$ISO_FILE" "${OUTPUT_DIR}/veilos-live-amd64.iso"
    cd "${OUTPUT_DIR}"
    sha256sum "veilos-live-amd64.iso" > "veilos-live-amd64.iso.sha256"
    echo "========================================================"
    echo "[SUCCESS] VEILOS ISO successfully generated!"
    echo "Location: ${OUTPUT_DIR}/veilos-live-amd64.iso"
    echo "SHA256: $(cat veilos-live-amd64.iso.sha256)"
    echo "========================================================"
else
    echo "[ERROR] ISO file was not generated. Check ${OUTPUT_DIR}/build.log for details."
    exit 1
fi
