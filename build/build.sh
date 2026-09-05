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
REQUIRED_TOOLS=(lb debootstrap xorriso squashfs-tools mksquashfs)
MISSING=()
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING+=("$tool")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "[!] Missing host build dependencies: ${MISSING[*]}"
    echo "    On Debian/Ubuntu, install with:"
    echo "    sudo apt-get update && sudo apt-get install -y live-build debootstrap xorriso squashfs-tools"
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

echo "[*] Cleaning previous build artifacts..."
lb clean --purge || true

echo "[*] Initializing live-build configuration..."
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