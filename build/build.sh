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

# Ensure executable permissions on all repository scripts
chmod +x "${ROOT_DIR}/config/includes.chroot/usr/local/bin/"* 2>/dev/null || true
chmod +x "${ROOT_DIR}/config/hooks/live/"* 2>/dev/null || true

# sync-rsvg-wrapper
# Ensure rsvg wrapper is available on host
if command -v rsvg-convert >/dev/null 2>&1; then
    ln -sf "$(command -v rsvg-convert)" /usr/local/bin/rsvg 2>/dev/null || true
    ln -sf "$(command -v rsvg-convert)" /usr/bin/rsvg 2>/dev/null || true
fi

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

# 5. Patch binary_syslinux to ensure chroot bootloader libraries exist before dereferencing
if [ -f /usr/lib/live/build/binary_syslinux ]; then
    echo "[*] Patching binary_syslinux with chroot bootloader library synchronization..."
    sed -i 's|/usr/bin/env rsvg |/usr/bin/env rsvg-convert |g' /usr/lib/live/build/binary_syslinux 2>/dev/null || true
    sed -i 's|rsvg |rsvg-convert |g' /usr/lib/live/build/binary_syslinux 2>/dev/null || true
    if ! grep -q "sync-syslinux-chroot" /usr/lib/live/build/binary_syslinux; then
        sed -i '/Chroot chroot cp -aL \/root\/\${_BOOTLOADER}/i \
# sync-syslinux-chroot\
mkdir -p chroot/usr/bin chroot/usr/local/bin\
if [ -x chroot/usr/bin/rsvg-convert ]; then\
    ln -sf /usr/bin/rsvg-convert chroot/usr/bin/rsvg 2>/dev/null || true\
    ln -sf /usr/bin/rsvg-convert chroot/usr/local/bin/rsvg 2>/dev/null || true\
elif command -v rsvg-convert >/dev/null 2>&1; then\
    cp -f "$(command -v rsvg-convert)" chroot/usr/bin/rsvg 2>/dev/null || true\
    cp -f "$(command -v rsvg-convert)" chroot/usr/bin/rsvg-convert 2>/dev/null || true\
fi\
mkdir -p chroot/usr/lib/ISOLINUX chroot/usr/lib/syslinux/modules/bios chroot/usr/lib/syslinux\
cp -rn /usr/lib/ISOLINUX/* chroot/usr/lib/ISOLINUX/ 2>/dev/null || true\
cp -rn /usr/lib/syslinux/* chroot/usr/lib/syslinux/ 2>/dev/null || true\
cp -rn /usr/lib/syslinux/modules/bios/* chroot/usr/lib/syslinux/modules/bios/ 2>/dev/null || true\
cp -rn /usr/lib/ISOLINUX/* chroot/usr/lib/syslinux/modules/bios/ 2>/dev/null || true\
cp -rn /usr/lib/syslinux/modules/bios/* chroot/usr/lib/ISOLINUX/ 2>/dev/null || true' /usr/lib/live/build/binary_syslinux
    fi
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
