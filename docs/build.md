# VEILOS Build Guide

This document details how to reproduce the **VEILOS Phase 1 Live ISO** from source.

## Overview of the Build Pipeline

```
SOURCE CONFIGURATION (config/, build/)
       │
       ▼
   build.sh
       │
       ▼
  live-build (Debian 12 Bookworm)
       ├── debootstrap (Minimal rootfs)
       ├── includes.chroot/ (VEILOS scripts, branding, autostart)
       ├── package-lists/ (Kernel, XFCE, Bubblewrap, Cryptsetup)
       └── mksquashfs + xorriso
       │
       ▼
veilos-live-amd64.iso (Hybrid UEFI/BIOS bootable live image)
```

---

## Prerequisites

To build the image natively, you require a 64-bit Linux environment (Debian 12, Ubuntu 22.04/24.04, or WSL2) with root/sudo privileges:

```bash
sudo apt-get update && sudo apt-get install -y \
  live-build \
  debootstrap \
  xorriso \
  squashfs-tools \
  dosfstools \
  isolinux \
  syslinux-common \
  grub-pc-bin \
  grub-efi-amd64-bin \
  mtools \
  rsync
```

---

## Method 1: Direct Native Build (Linux / WSL2)

1. Clone or navigate to the VEILOS repository:
   ```bash
   cd Veil
   ```
2. Make scripts executable:
   ```bash
   chmod +x build/*.sh config/auto/* config/hooks/live/* config/includes.chroot/usr/local/bin/* tests/*.sh
   ```
3. Run the automated build script with `sudo`:
   ```bash
   sudo ./build/build.sh
   ```
4. Upon successful completion, your ISO will be placed in:
   ```
   output/veilos-live-amd64.iso
   output/veilos-live-amd64.iso.sha256
   ```

---

## Method 2: Containerized Build (Docker / Podman)

If you have Docker installed on your host machine:

1. Build the builder image:
   ```bash
   docker build -t veilos-builder -f build/Dockerfile.builder .
   ```
2. Run the build container with privileged capability (required for `debootstrap` and loop mounts):
   ```bash
   docker run --rm --privileged -v "$(pwd):/workspace" veilos-builder
   ```

---

## Method 3: Cloud / GitHub Actions CI (Zero Host Tooling)

Pushing changes to the repository or triggering the workflow manually via GitHub Actions builds the image on Ubuntu runners automatically and attaches the ISO as an artifact:

* **Workflow:** `.github/workflows/build-iso.yml`
* **Artifact:** `veilos-live-amd64.zip` containing `veilos-live-amd64.iso` and checksum.

---

## How to Test and Boot the ISO

### Using QEMU:
```bash
qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -cdrom output/veilos-live-amd64.iso \
  -boot d \
  -vga virtio \
  -enable-kvm
```

### Using VirtualBox:
1. Create a new VM: Type **Linux**, Version **Debian (64-bit)**.
2. Allocate at least **2048 MB RAM**.
3. Attach `output/veilos-live-amd64.iso` to the Optical Drive.
4. Start VM. It will automatically boot into the VEILOS live desktop.

### Flashing to a USB Drive:
```bash
sudo dd if=output/veilos-live-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```
*(Replace `/dev/sdX` with your target flash drive).*