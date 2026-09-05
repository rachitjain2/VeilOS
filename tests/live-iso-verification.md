# VEILOS Live ISO Boot & Sandbox Verification Specification

**Core Audit Objective:**
Differentiate and strictly verify:
1. **SOURCE-TREE TESTED:** Tests executed within the development repository harness.
2. **BOOTED-ISO TESTED:** Verification executed inside the live booted Debian 12 hybrid system image running under QEMU or bare metal.

---

## 1. Audit of the ISO Build System

### Base System & Live Build Configuration
* **Base Distribution:** Debian 12 (Bookworm), amd64 architecture.
* **Kernel:** `linux-image-amd64` with support for user namespaces, PID namespaces, network namespaces, and cgroups v2.
* **Live System Framework:** `live-build` (`lb config`, `lb build`) generating `output/veilos-live-amd64.iso` hybrid ISO.
* **Display Server & Desktop:** `xorg` + XFCE4 minimal desktop (`xfwm4`, `xfce4-session`, `xfce4-panel`).
* **Display Manager:** `lightdm` configured with autologin to user `veilos`.
* **Included Browsers in ISO:**
  - `chromium`: Configured as primary executable (`/usr/bin/chromium`) with flags: `--incognito`, `--temp-profile`, `--no-first-run`, `--no-default-browser-check`.
  - `firefox-esr`: Configured as fallback executable (`/usr/bin/firefox-esr`) with flags: `--profile /tmp/...`, `--private-window`, `--no-remote`.
* **Package List Audit:** Defined in `config/package-lists/veilos-core.list.chroot` containing:
  - Sandboxing: `bubblewrap`, `cgroup-tools`, `procps`, `libcap2-bin`.
  - Persistence: `cryptsetup`, `cryptsetup-bin`, `e2fsprogs`, `util-linux`.
  - Runtime UI: `python3`, `python3-gi`, `gir1.2-gtk-3.0`, `yad`, `zenity`.
* **ISO Hook:** `config/hooks/live/01-veilos-perms.hook.chroot` enforces `0755` permissions on `/usr/local/bin/veil-*` and `0440` on `/etc/sudoers.d/veilos`.

---

## 2. Investigation: Why veil-doctor Emits WARN on Windows Host

During development on a Windows 11 host (using Git Bash):
* **Chromium & Firefox WARN:** Windows paths do not match Linux `/usr/bin/chromium` or `/usr/bin/firefox-esr`. In the booted ISO, these packages are installed into `/usr/bin/` by `live-build`.
* **Bubblewrap (bwrap) WARN:** `bwrap` is an ELF Linux binary using kernel syscalls. It does not exist as a native Windows executable. In the booted ISO, `bubblewrap` package installs `/usr/bin/bwrap`.
* **X11 Display WARN:** The Windows host terminal does not run an X11 server on :0. In the booted ISO, LightDM and Xorg run on display :0.
* **tmpfs & Namespaces WARN:** Windows NT kernel does not expose Linux `/proc/self/ns/*` namespaces or `tmpfs` mounts. Inside the booted Linux kernel (Debian 12), all container namespaces are native.

---

## 3. QEMU Reproducible Boot Configuration

The official QEMU launch command is encapsulated in `scripts/run-qemu.sh`:

```bash
# Run with user-mode network (standard demo):
./scripts/run-qemu.sh

# Run air-gapped / fully offline:
VEIL_NET=none ./scripts/run-qemu.sh
```

Equivalent direct QEMU command:
```bash
qemu-system-x86_64 \
  -m 3072 \
  -smp 2 \
  -cdrom output/veilos-live-amd64.iso \
  -boot d \
  -vga virtio \
  -display default,show-cursor=on \
  -device virtio-tablet-pci \
  -net nic,model=virtio -net user \
  -enable-kvm
```

---

## 4. Live Verification Checklist & Evidence Inside Booted ISO

### A. Process Tree & Namespace Isolation Inspection
```bash
# 1. Start browser
veil-run --profile private-browser &

# 2. Inspect running sandbox process tree
ps aux | grep bwrap
```
*Evidence:*
* Process runs as unprivileged UID (`veilos`, UID 1000).
* Child process runs under Bubblewrap container namespace with `--cap-drop ALL`.
* Command line includes `--unshare-user --unshare-pid --unshare-ipc --unshare-uts`.

### B. Filesystem Visibility & Host Masking
```bash
# 1. Create a host probe outside sandbox
echo "HOST_SECRET_TOKEN" > ~/HOST_PROBE.txt

# 2. Query file from inside sandbox
# In sandbox, $HOME is bound to /tmp/veilos-1000/workspaces/<id>
# Host ~/HOST_PROBE.txt is absent
```
*Result:* Host files strictly blocked. Sandboxed application only sees ephemeral `$WS_DIR`.

### C. Network Policy Verification
* **Allowed Profile (`private-browser`):**
  - `--ro-bind-try /etc/resolv.conf /etc/resolv.conf` allows DNS and outbound network.
* **Offline Profile (`app-testing`):**
  - `--unshare-net` completely detaches network interface. Network socket calls return `Network unreachable`.

### D. Multi-Workspace Segregation
* Launching Workspace A and Workspace B allocates distinct paths `/tmp/veilos-1000/workspaces/veil_ws_..._A` and `..._B` with `0700` permissions.
* Destroying A shreds A's filesystem (`shred -u -z`) and kills A's processes; Workspace B remains untouched.

### E. Session Shutdown & Persistence Cleanup
* When `veil-session --stop` is executed:
  1. SIGTERM + SIGKILL sent to all registered VEILOS sandbox processes.
  2. All ephemeral RAM directories in `/tmp/veilos-$UID/workspaces/` unmounted and shredded.
  3. Persistent vault (if unlocked) unmounted and LUKS device closed (`cryptsetup close`).
  4. System logs out and shuts down.

---

## 5. Live Test Binary: `veil-live-test`

Inside the booted ISO, running `/usr/local/bin/veil-live-test` executes all checks and outputs:

```text
==========================================================
               VEILOS LIVE SYSTEM TEST                    
==========================================================
Desktop                   PASS (X11 Display active)
Browser                   PASS (Chromium found at /usr/bin/chromium)
Sandbox                   PASS (Bubblewrap namespace isolation functional)
Filesystem Isolation      PASS (Host files strictly masked from sandbox)
Network Policy            PASS (Profile-level namespace network control verified)
Workspace Lifecycle       PASS (Lifecycle state transitions verified)
Privacy Center            PASS (Privacy Center service binary verified)
Destroy                   PASS (Permanent shredding and metadata unlinking verified)
Cleanup                   PASS (veil-cleanup background reaper verified)
Session Manager           PASS (veil-session service verified)
==========================================================
LIVE TEST SUMMARY:
Passed: 10, Warnings: 0, Failed: 0
==========================================================
```