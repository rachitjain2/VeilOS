# 🛡️ VEILOS — Disposable Computing Operating System

[![Hackathon Edition](https://img.shields.io/badge/Edition-VEILOS--HACKATHON_v0.1-blueviolet?style=for-the-badge&logo=linux)](config/includes.chroot/etc/veilos/version.json)
[![Kernel](https://img.shields.io/badge/Kernel-Debian_12_Bookworm_amd64-red?style=for-the-badge&logo=debian)](config/auto/config)
[![Isolation Engine](https://img.shields.io/badge/Isolation-Bubblewrap_Namespaces-success?style=for-the-badge&logo=security)](config/includes.chroot/usr/local/bin/veil-run)
[![Tests](https://img.shields.io/badge/Tests-15%2F15_Passing-brightgreen?style=for-the-badge&logo=checkmarx)](tests/run_all_tests.sh)
[![Status](https://img.shields.io/badge/Security-Honest_&_Verified-orange?style=for-the-badge&logo=shield)](docs/security-model.md)

> **"What if applications were guests instead of owners?"**  
> Traditional operating systems grant installed software persistent co-ownership over your personal storage, background sockets, and hardware peripherals.  
> **VEILOS flips this paradigm.** Every computing session and every application is ephemeral by default: running in volatile RAM namespaces with zero host access, disposable by design, and erased with cryptographic shredding.

---

## 👥 The Team Behind VEILOS

| Name | Role | Responsibilities |
| :--- | :--- | :--- |
| **Rachit Jain** | 🛠️ **Lead Engineer** | Core OS Architecture, Sandbox Policy Engine (`veil-run`), Kernel Namespaces, ISO Build Pipeline |
| **Bhumi Arora** | 📋 **Project Manager** | Product Roadmapping, Scope Governance, Hackathon Deliverables, Quality Assurance |
| **Yash Singhal** | 🧪 **User Tester** | Security Edge-Case Audits, Multi-Workspace Isolation Testing, Penetration Verification |
| **Prastuti Mushahary** | 🎨 **Lead Designer** | Desktop Interface, Privacy Center Visuals, UX Workflow, Proof-Oriented UI Components |
| **Preet Kumar** | 🎤 **Presenter** | Product Storytelling, Judge Demonstrations, Value Proposition, Technical Q&A Pitching |

---

## ✨ Core Philosophy: Disposable Computing

When you boot VEILOS from a USB drive or virtual machine:
* 🧼 **Zero Installation on Host:** Runs 100% in RAM (`tmpfs`). Your Windows or Mac hard drive is never touched, mounted, or modified.
* 🚫 **Host Filesystem Masking:** Personal files, configurations, and raw drives are completely unmounted and blocked from sandboxed applications.
* ⚡ **Bare-Metal Hardware Speed:** Unlike resource-heavy virtual machines (10x overhead) or laggy cloud PCs, VEILOS utilizes native Linux kernel namespaces directly on bare metal.
* 💥 **True Cryptographic Destruction:** STOP and DESTROY are distinct operations. Destroying a workspace kills child processes (`SIGTERM` + `SIGKILL`) and scrubs memory with `shred -u -z -n 1`.
* 🔒 **Encrypted Persistence as an Exception:** If a user explicitly chooses to save a file, it is preserved in an AES-256-XTS LUKS encrypted **Secure Vault**.
* 🔍 **Honest Security Transparency:** We never fake security. Known architectural limits (like X11 shared sockets) are transparently disclosed in our **Privacy Center**.

---

## 🖥️ System Architecture

```
                        VEILOS DESKTOP & LAUNCHER
                                    │
            ┌───────────────────────┼───────────────────────┐
            ▼                       ▼                       ▼
   🌐 Private Browser     💻 Developer Studio      🧪 App Testing Jail
   (Chromium/Firefox)     (Node, Python, Git)     (Air-gapped Zero-Trust)
            │                       │                       │
            └───────────────────────┼───────────────────────┘
                                    ▼
                      APPLICATION PROFILES ENGINE
                     (/etc/veilos/profiles/*.json)
                                    │
                                    ▼
                       SANDBOX RUNTIME (veil-run)
              ┌─────────────────────┴─────────────────────┐
              ▼                                           ▼
     LINUX KERNEL NAMESPACES                    VOLATILE TMPFS STORAGE
  • User Namespace (--unshare-user)            • Ephemeral Home Directory
  • PID Namespace  (--unshare-pid)             • Masked Host Filesystem
  • IPC Namespace  (--unshare-ipc)             • Cryptographic Shredding
  • UTS Namespace  (--unshare-uts)             • Zero Disk Artifacts
  • Capabilities Dropped (--cap-drop ALL)      • Auto-Reaped by veil-cleanup
```

---

## 🚀 Predefined Environments

### 1. 🌐 Private Browser
* **Executable:** Chromium / Firefox ESR fallback.
* **Policy:** Outbound internet ALLOWED, host files BLOCKED, camera/mic BLOCKED, cookies & cache VOLATILE.
* **Launch:** `veil-run --profile private-browser`

### 2. 💻 Developer Workspace
* **Toolchain:** Node.js, Python 3, Git, npm, pip, build-essential (`gcc`, `g++`, `make`), Geany editor.
* **Policy:** Ephemeral workspace in RAM; allows package installation (`npm install`, `pip install`) with zero pollution of the host system.
* **Launch:** `veil-run --profile development`

### 3. 🧪 App Testing Sandbox
* **Policy:** Zero-trust jail; network completely air-gapped (`--unshare-net`), camera/mic/USB blocked, strict cgroup memory quotas.
* **Launch:** `veil-run --profile app-testing`

### 4. 🔐 Secure Vault
* **Mechanism:** AES-256-XTS LUKS dm-crypt container for explicit user-selected persistent data.
* **Launch:** `veilos-vault-gui`

### 5. 🛡️ Privacy Center & Proof Screen
* **Capabilities:** Real-time workspace telemetry, live duration counters, minimal audit log viewer, and honest security badges (`✓ ENFORCED`, `◐ PARTIAL`, `○ NOT IMPLEMENTED`).
* **Launch:** `veilos-privacy-center`

---

## 🛠️ Verification & Test Suite

VEILOS includes a comprehensive **15-suite automated test harness** verifying syntax, profiles, container boundaries, concurrency, and destruction proofs:

```bash
# Run the master test runner (15/15 tests passing)
./tests/run_all_tests.sh

# Pre-flight diagnostic check
veil-doctor

# Pre-demo system check & safe preparation
veil-hackathon-demo

# 15-step primary demo smoke test
./tests/demo-smoke-test.sh

# Multi-workspace isolation & survivability test
./tests/isolation-test.sh
```

---

## 📦 Building the Bootable Live ISO

VEILOS builds an official hybrid live ISO using Debian 12 `live-build`:

```bash
# 1. Install build tools (Debian / Ubuntu / WSL2)
sudo apt-get update && sudo apt-get install -y \
  live-build debootstrap xorriso squashfs-tools dosfstools isolinux mtools

# 2. Trigger automated build
sudo ./build.sh
```

The output image is produced at:  
`output/veilos-live-amd64.iso` (and verified via `output/veilos-live-amd64.iso.sha256`)

---

## 💻 Testing in QEMU Virtual Machine

Launch the ISO reproducibly using our launcher script:
```bash
./scripts/run-qemu.sh output/veilos-live-amd64.iso
```

---

## 📖 Documentation Quick Links

* 🎤 [30-Second Pitch](docs/30-second-pitch.md)
* ⏱️ [3-Minute Judge Pitch](docs/3-minute-pitch.md)
* 🎬 [Final Hackathon Demo Script](docs/final-demo-script.md)
* ❓ [Judge Questions & Answers (13 FAQs)](docs/judge-questions.md)
* 🏛️ [System Architecture Overview](docs/architecture-overview.md)
* 🛡️ [Security Model & Honest Disclosures](docs/security-model.md)
* 🛟 [Fallback & Recovery Plan](docs/fallback-demo.md)
* 🔨 [Full ISO Build Specification](docs/build.md)

---

## ⚖️ Transparent Limitations (Honest Security)

1. **X11 Display Protocol:** Under X11, clients sharing `DISPLAY=:0` can theoretically monitor window events. Migration to pure Wayland nested compositors (Wayfire/Cage) is planned for v2.0.
2. **Profile-Level Network Controls:** Network policy is binary (`ALLOWED` vs. `AIR-GAPPED`). Per-domain deep packet filtering is not enforced at the application level.
3. **Hardware DRAM Remanence:** Volatile memory is wiped at shutdown, but live physical hardware cold-boot acquisition while powered on is outside our threat model.

---

<div align="center">
  <b>Built with ❤️ by the VEILOS Team for the Hackathon.</b><br>
  <i>Private Computing by Default.</i>
</div>
