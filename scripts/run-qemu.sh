#!/bin/bash
# ==============================================================================
# VEILOS QEMU Live ISO Reproducible Launcher
# Boots the generated VEILOS Live Hybrid ISO in a sandboxed QEMU virtual machine
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/output"
ISO_IMAGE="${OUTPUT_DIR}/veilos-live-amd64.iso"

# Check for custom ISO path argument
if [[ $# -gt 0 && -f "$1" ]]; then
    ISO_IMAGE="$1"
fi

echo "=========================================================="
echo "          VEILOS QEMU VIRTUAL MACHINE LAUNCHER            "
echo "=========================================================="

if [[ ! -f "$ISO_IMAGE" ]]; then
    echo "[!] Error: VEILOS ISO image not found at: ${ISO_IMAGE}"
    echo "    Please build the ISO first with: sudo ./build.sh"
    echo "    Or provide the ISO path: ./scripts/run-qemu.sh /path/to/image.iso"
    exit 1
fi

echo "Target ISO: ${ISO_IMAGE}"
echo "Image Size: $(du -h "$ISO_IMAGE" | cut -f1)"

# Check QEMU binary availability
QEMU_BIN=""
for candidate in qemu-system-x86_64 qemu-system-x86_64.exe; do
    if command -v "$candidate" >/dev/null 2>&1; then
        QEMU_BIN="$candidate"
        break
    fi
done

if [[ -z "$QEMU_BIN" ]]; then
    echo "[!] Error: 'qemu-system-x86_64' not found in PATH."
    echo "    To install QEMU:"
    echo "    - Debian/Ubuntu: sudo apt-get install -y qemu-system-x86"
    echo "    - Arch Linux:    sudo pacman -S qemu-desktop"
    echo "    - macOS:         brew install qemu"
    echo "    - Windows:       winget install SoftwareFreedomConservancy.QEMU"
    exit 1
fi

echo "Using QEMU: $($QEMU_BIN --version | head -n 1)"

# Architecture & Acceleration Detection
KVM_FLAG=()
if [[ -e /dev/kvm && -w /dev/kvm ]]; then
    echo "KVM Hardware Acceleration: ENABLED"
    KVM_FLAG=(-enable-kvm -cpu host)
elif [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Hypervisor.framework Acceleration: ENABLED"
    KVM_FLAG=(-accel hvf -cpu host)
elif [[ "$(uname -o 2>/dev/null)" == "Msys" ]] || [[ "$(uname -s)" =~ MINGW|MSYS|CYGWIN ]]; then
    if "$QEMU_BIN" -accel help 2>&1 | grep -q whpx; then
        echo "Windows Hypervisor Platform (WHPX): AVAILABLE"
        KVM_FLAG=(-accel whpx -cpu host)
    else
        echo "Hardware Acceleration: NONE (Emulated x86_64)"
        KVM_FLAG=(-cpu max)
    fi
else
    echo "Hardware Acceleration: NONE (Falling back to software emulation)"
    KVM_FLAG=(-cpu max)
fi

# RAM & Cores Allocation
RAM_MB="${VEIL_RAM:-3072}"
SMP_CORES="${VEIL_SMP:-2}"
NET_MODE="${VEIL_NET:-user}" # Set VEIL_NET=none for air-gapped test

QEMU_CMD=(
    "$QEMU_BIN"
    "${KVM_FLAG[@]}"
    -m "${RAM_MB}"
    -smp "${SMP_CORES}"
    -cdrom "${ISO_IMAGE}"
    -boot d
    -vga virtio
    -display default,show-cursor=on
    -device virtio-tablet-pci
    -name "VEILOS Live Operating System [Disposable]"
)

# Network Configuration
if [[ "$NET_MODE" == "none" ]]; then
    echo "Network Policy: AIR-GAPPED / OFFLINE (No NIC connected)"
    QEMU_CMD+=(-net none)
else
    echo "Network Policy: USERMODE NAT (Outbound allowed)"
    QEMU_CMD+=(-net nic,model=virtio -net user)
fi

echo ""
echo "[*] Launching VEILOS in QEMU..."
echo "Command: ${QEMU_CMD[*]}"
echo "=========================================================="

exec "${QEMU_CMD[@]}"
