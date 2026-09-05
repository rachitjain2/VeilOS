# VEILOS Reproducible Live ISO Build Specification

This guide explains how to generate the official bootable **VEILOS Live Hybrid ISO** from source.

```
VEILOS SOURCE (config/, build/, src/)
          │
          ▼
       build.sh
          │
          ▼
   Debian 12 Live-Build
   ├── debootstrap (Bookworm minimal base)
   ├── includes.chroot/ (Dashboard, veil-run, veil-session, veil-cleanup)
   ├── package-lists/ (Kernel, XFCE4, Bubblewrap, Cryptsetup, Dev tools)
   └── mksquashfs + xorriso
          │
          ▼
VEILOS LIVE ISO (output/veilos-live-amd64.iso)
          │
          ▼
BOOT FROM USB / QEMU
          │
          ▼
VEILOS DESKTOP & PRIVATE DASHBOARD
```

---

## 1. System Requirements & Specifications

| Requirement | Specification |
| :--- | :--- |
| **Supported Host OS** | Debian 12 (Bookworm), Ubuntu 22.04 / 24.04 LTS, or Windows with WSL2 (Debian/Ubuntu) |
| **Privileges** | `root` / `sudo` access (required for `debootstrap`, `chroot`, and loop mounting) |
| **Minimum RAM** | **4 GB RAM** (8 GB recommended for faster squashfs compression) |
| **Minimum Disk Space** | **15 GB free disk space** |
| **Estimated Build Time**| **10 to 20 minutes** (depending on internet bandwidth and CPU core count) |
| **Architecture** | `amd64` (x86_64) |
| **Target Bootloaders** | Hybrid BIOS (`syslinux`/`isolinux`) + UEFI (`grub-efi-amd64`) |

---

## 2. Host Build Dependencies

On your Debian/Ubuntu or WSL2 host, install the necessary packaging and image tools:

```bash
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
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
  rsync \
  curl \
  ca-certificates
```

---

## 3. Building the ISO

From the root directory of the repository:

```bash
# 1. Grant execution permissions
chmod +x build.sh build/*.sh config/auto/* config/hooks/live/* config/includes.chroot/usr/local/bin/* tests/*.sh

# 2. Trigger the automated build
sudo ./build.sh
```

### Build Artifacts:
Upon completion, the build script generates and verifies:
* `output/veilos-live-amd64.iso` (~1.4 GB bootable hybrid ISO)
* `output/veilos-live-amd64.iso.sha256` (Cryptographic verification checksum)
* `output/build.log` (Full build transcript)

---

## 4. Alternative Build Method: Docker Container

If building on a machine with Docker installed:

```bash
# 1. Build builder image
docker build -t veilos-builder -f build/Dockerfile.builder .

# 2. Execute isolated build (privileged flag needed for debootstrap chroot)
docker run --rm --privileged -v "$(pwd):/workspace" veilos-builder
```

---

## 5. Alternative Build Method: GitHub Actions CI (Zero Host Setup)

Every push or manual trigger in GitHub runs `.github/workflows/build-iso.yml`:
* Runs cleanly on `ubuntu-24.04` GitHub runners.
* Produces and uploads `veilos-live-amd64.iso` as a downloadable GitHub Actions artifact.

---

## 6. How to Test in QEMU

Test the live image inside a virtual machine with 2 GB RAM and KVM hardware acceleration:

```bash
qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -cdrom output/veilos-live-amd64.iso \
  -boot d \
  -vga virtio \
  -enable-kvm
```

*(On Windows without KVM, omit `-enable-kvm` or run inside Hyper-V/VirtualBox).*

---

## 7. How to Write the ISO to a USB Drive

To create a bootable live USB stick:

### Linux / macOS:
```bash
# Identify your USB drive (e.g. /dev/sdX - DO NOT target your system drive)
lsblk

# Flash ISO image
sudo dd if=output/veilos-live-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

### Windows:
Use **Rufus** (in *DD Image Mode*) or **BalenaEtcher** to write `veilos-live-amd64.iso` to a USB drive.

---

## 8. Verified 10-Step Boot & Runtime Workflow

When VEILOS boots:
1. **Live Boot:** Boots into RAM via `live-boot` with `hostname=VEILOS` and `noautomount`.
2. **Auto-Login:** LightDM automatically enters the `veilos` live desktop.
3. **Session Initialization:** `veilos-session-startup` initializes volatile storage; `veilos-dashboard` opens center screen.
4. **Private Browser:** Clicking launches `veil-run --profile private-browser` inside an ephemeral namespace.
5. **Developer Workspace:** Clicking launches `veil-run --profile development` with Node, Python, Git, and isolated package support.
6. **App Sandbox / Testing:** Clicking launches `veil-run --profile app-testing` with zero-trust network blocking and memory quotas.
7. **Privacy Center:** Shows live policy audit, status, and honest `✓ ENFORCED` badges.
8. **Destroy Sandbox:** Click `[ DESTROY ENVIRONMENT ]` in Privacy Center; `veilos-destroy-env` terminates all child processes and shreds temporary RAM.
9. **Secure Vault:** Click `[ SECURE VAULT ]` to unlock/lock an encrypted LUKS container for explicit data persistence.
10. **End Session:** Click `[ END SESSION ]`; `veil-session` halts all containers, locks the vault, wipes memory, and logs out.

---

## 9. Known Limitations (Honest Security Disclosure)

1. **X11 Display Architecture:** Applications sharing the X11 server on `/tmp/.X11-unix/X0` can theoretically intercept keystrokes or record screen pixels. Migration to pure Wayland is planned for v2.0.
2. **Forensic DRAM Remanence:** Cold boot physical hardware attacks against memory chips immediately after power loss are not mitigated by software live OSes.
3. **External Unencrypted Swap:** VEILOS does not mount host swap partitions, but if booted on firmware that forces swap activation without encryption, pages could leak.