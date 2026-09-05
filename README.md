# VEILOS — Disposable Computing Operating System

> **Applications are guests, not owners.**

VEILOS is a privacy-focused, amnesic Linux-based live operating system prototype designed around the paradigm of **Disposable Computing**.

---

## The Vision

Traditional operating systems treat applications as privileged co-owners of your device: once installed, applications can inspect your personal files, probe hardware peripherals, maintain permanent telemetry caches, and leave lingering artifacts across your filesystem.

VEILOS flips this paradigm:
* Applications launch into **ephemeral, isolated namespaces** in volatile RAM.
* Applications receive **zero persistent storage by default**.
* Access to personal files, webcam, microphone, and raw disks is **blocked**.
* Preserving data requires an **explicit user action** to shuttle files into a LUKS2 encrypted **Secure Vault**.
* Destroying a workspace or ending a session **overwrites and obliterates** temporary memory state.

---

## Core Desktop Subsystems

```
┌─────────────────────────────────────────────────────────────┐
│                    VEILOS MAIN DASHBOARD                    │
│                     PRIVATE COMPUTING                       │
├─────────────────────────────────────────────────────────────┤
│ SESSION: ● TEMPORARY             NETWORK: ● PROTECTED       │
│ PERSISTENCE: ● OFF (VOLATILE)    PRIVACY: ACTIVE (0 WS)     │
├─────────────────────────────────────────────────────────────┤
│  [ PRIVATE BROWSER ]         Firefox in ephemeral RAM       │
│  [ DEVELOPER WORKSPACE ]     Node, Python, Git, npm, pip    │
│  [ APP TESTING ]             Zero-trust offline sandbox     │
│  [ SECURE VAULT ]            LUKS2 dm-crypt persistence     │
│  [ PRIVACY CENTER ]          Live transparency audit        │
│  [ END SESSION ]             Scrub memory & log out         │
└─────────────────────────────────────────────────────────────┘
```

1. **Private Browser (`veil-run --profile private-browser`):** Isolated web browser running in memory with masked host files.
2. **Developer Workspace (`veil-run --profile development`):** Ephemeral coding studio with Node.js, Python 3, Git, npm, pip, and gcc/g++, allowing package installs strictly inside the disposable workspace.
3. **App Testing Sandbox (`veil-run --profile app-testing`):** Zero-trust offline jail with blocked camera, mic, USB, and 1024 MB RAM limits.
4. **Secure Vault (`veilos-vault-gui`):** AES-256-XTS LUKS2 encrypted volume manager for explicit data preservation.
5. **Privacy Center (`veilos-privacy-center`):** Honest security audit displaying `✓ ENFORCED` vs `◐ PARTIAL` status and "Why?" policy explanations.
6. **Session Manager (`veil-session`):** Enforces temporary boot sessions and orchestrates complete RAM scrubbing on shutdown.
7. **Lifecycle & Reaper (`veil-cleanup`):** Tracks state (`CREATING` → `RUNNING` → `STOPPING` → `DESTROYED`) and reaps orphaned sandboxes.

---

## Reproducible ISO Build Pipeline

The complete pipeline transforms source code into a bootable hybrid ISO:

```
SOURCE CONFIGURATION ──► build.sh ──► VEILOS LIVE ISO ──► BOOT USB ──► DESKTOP
```

### Quick Build (Debian 12, Ubuntu, or WSL2):
```bash
# 1. Install build dependencies
sudo apt-get update && sudo apt-get install -y \
  live-build debootstrap xorriso squashfs-tools dosfstools \
  isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin mtools rsync

# 2. Build the ISO
sudo ./build.sh
```

The resulting hybrid ISO is generated at:
```
output/veilos-live-amd64.iso
output/veilos-live-amd64.iso.sha256
```

Detailed instructions for **Docker builds**, **GitHub Actions CI**, **QEMU virtual machine testing**, and **USB flashing** are documented in [docs/build.md](docs/build.md).

---

## Verification & Automated Test Suite

VEILOS includes an automated test suite verifying all sandbox policies and security controls:

```bash
# Run all tests
bash tests/test_syntax.sh
bash tests/test_veil_run.sh
bash tests/test_private_browser.sh
bash tests/test_dev_workspace.sh
bash tests/test_app_testing.sh
bash tests/test_secure_vault.sh
bash tests/test_privacy_center.sh
bash tests/test_session_manager.sh
bash tests/test_lifecycle_cleanup.sh
bash tests/test_security_hardening.sh
```

---

## Security Philosophy & Limitations

VEILOS adheres to honest security engineering:
* **No "100% Secure" Claims:** We never claim zero-trace forensics or uncrackable systems.
* **X11 Limitation:** On standard X11 desktops, cross-window keylogging is a known protocol constraint. Migration to pure Wayland is planned for v2.0.
* **Cold Boot Remanence:** Residual hardware memory traces on power-off are inherent to DRAM hardware and are not fully eliminated by software-only live distros.