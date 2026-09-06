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

# Create host isohybrid wrapper so binary stage never fails if image is already hybridized
cat << 'EOF' > /usr/local/bin/isohybrid
#!/bin/sh
if [ -x /usr/bin/isohybrid ]; then
    /usr/bin/isohybrid "${@}" 2>/dev/null || true
fi
exit 0
EOF
chmod +x /usr/local/bin/isohybrid 2>/dev/null || true
chmod +x "${ROOT_DIR}/config/includes.chroot/usr/local/bin/"* 2>/dev/null || true

# Ensure syslinux and ISOLINUX paths are cross-linked for live-build
if [ -d /usr/lib/ISOLINUX ] && [ ! -e /usr/lib/syslinux/isolinux.bin ]; then
    mkdir -p /usr/lib/syslinux
    cp -rn /usr/lib/ISOLINUX/* /usr/lib/syslinux/ 2>/dev/null || true
fi
if [ -d /usr/lib/syslinux ] && [ ! -e /usr/lib/ISOLINUX/isolinux.bin ]; then
    mkdir -p /usr/lib/ISOLINUX
    cp -rn /usr/lib/syslinux/* /usr/lib/ISOLINUX/ 2>/dev/null || true
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