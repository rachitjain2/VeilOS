# VEILOS Security Model & Threat Model (Plain English)

**Guiding Principle:**
> *"Never fake security enforcement. Disclose exact protection boundaries, document what is protected, what is not protected, and explain the why."*

---

## 1. What VEILOS Protects Against

1. **Host Filesystem Snooping:**
   Applications launched inside a VEILOS sandbox run with isolated mount namespaces created by Bubblewrap (`bwrap`). The user's host home directory, external drives, and configuration files are unmounted and completely inaccessible to sandboxed applications.
2. **Persistent Forensic Artifacts:**
   Applications operate inside temporary `tmpfs` workspaces created in RAM. Browser cookies, history, downloaded caches, and temporary scratch files are purged and overwritten (`shred -u -z`) upon workspace destruction.
3. **Cross-Workspace Data Bleeding:**
   Each running workspace receives an isolated, randomly generated identifier (`veil_ws_<profile>_<timestamp>_<rand>`) with permissions `0700`. Workspaces cannot read or write to other active workspace filesystems.
4. **Privilege Escalation inside Sandboxes:**
   All sandboxes execute with `--unshare-user` and `--cap-drop ALL`. Sandboxed processes run unprivileged and cannot manipulate system hardware, load kernel modules, or remount filesystems.
5. **Dangling or Orphaned Sandbox Processes:**
   Child processes spawned inside workspaces are tracked via metadata records. During workspace destruction or session end, processes receive `SIGTERM` followed by `SIGKILL`, and the `veil-cleanup` daemon reaps abandoned or crashed containers.

---

## 2. What VEILOS Does NOT Protect Against (Known Limitations)

1. **X11 Display Protocol Inherent Insecurities:**
   VEILOS currently runs under an Xorg/X11 desktop environment. Because X11 was not designed with application isolation, any application with an active connection to the X server (`DISPLAY=:0`) could theoretically inspect keystrokes or capture window screenshots from other X11 clients.
   - *Future Roadmap:* Complete migration to a Wayland-based display server with nested compositors (such as `gamescope` or `cage`) to isolate input and surface buffers.
2. **Coarse-Grained Network Filtering:**
   Network controls are currently binary at the sandbox boundary: either network access is **ALLOWED** (for browser and development workspaces) or **OFFLINE / AIR-GAPPED** (via `--unshare-net` for restricted app testing). Subnet-level packet filtering or per-domain firewalls are not enforced at the application level.
3. **Hardware / Microarchitectural Side Channels:**
   VEILOS does not mitigate speculative execution attacks (e.g., Spectre/Meltdown) across CPU threads or GPU shared memory buffers.
4. **Physical RAM Acquisition:**
   While volatile memory is discarded at shutdown and temporary files are shredded on destroy, a live forensic physical dump of system RAM while a workspace is running could reveal active process memory.

---

## 3. Sandboxing Architecture

VEILOS utilizes standard, peer-reviewed Linux primitives rather than custom in-tree drivers or unverified crypto:

- **Bubblewrap (`bwrap`):** Creates unprivileged user, mount, PID, IPC, and UTS namespaces.
- **tmpfs Mounts:** Ephemeral home directories and volatile caches reside purely in RAM.
- **cgroups (v2):** Configured to place resource caps (memory ceilings, CPU quotas, process limits) on untrusted processes.
- **Secure Shredding:** Files deleted during workspace destruction are scrubbed using `shred -u -z -n 1` before the directory node is removed.
- **LUKS / dm-crypt:** For persistent Secure Vault storage, utilizing standard AES-XTS full-disk or loopback encryption.

---

## 4. Audit Logging & User Privacy

VEILOS maintains an internal security audit trail (`audit.log`) recording operational lifecycle transitions:
- `WORKSPACE_CREATED`
- `SANDBOX_STARTED`
- `APPLICATION_STARTED`
- `APPLICATION_STOPPED`
- `DESTROY_REQUESTED`
- `SANDBOX_DESTROYED`
- `CLEANUP_COMPLETED`

**Privacy Guarantee:** Audit logs record only system state and workspace identifiers. **No browsing URLs, search queries, passwords, user keystrokes, or document payloads are ever recorded.**
