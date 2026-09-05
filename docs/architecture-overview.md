# VEILOS Architecture Overview

```
VEILOS Desktop (XFCE4 / Dashboard)
       │
       ▼
Application Profile (/etc/veilos/profiles/*.json)
       │
       ▼
Policy Engine (Argument translation & boundary setup)
       │
       ▼
Sandbox Manager (veil-run & veil-cleanup)
       │
       ▼
Linux Isolation Primitives (Bubblewrap, cgroups, tmpfs, namespaces)
       │
       ▼
Isolated Application (Chromium / Node.js / Python)
```

---

## 1. Simple Language Explanation

* **Think of VEILOS like a hotel room for software:** When an application enters, it gets clean sheets, its own key, and its own private space. It cannot open the hotel's master safe or walk into other guests' rooms. When it checks out, the room is scrubbed clean, and no luggage is left behind.

---

## 2. Technical System Components

### A. Filesystem Isolation
* The host `/home` directory is completely masked from the sandbox mount namespace.
* System directories (`/usr`, `/lib`, `/bin`, `/etc`) are bound read-only.
* The application's home directory is bound to a unique temporary `tmpfs` directory in RAM.

### B. Network Isolation
* Profile-driven network policy: Outbound web permitted for browser/developer profiles; air-gapped via `--unshare-net` for untrusted app testing.

### C. Temporary Storage & Cryptographic Destruction
* All volatile data created during an application run exists in RAM only.
* Upon workspace destruction, files are wiped using cryptographic overwriting (`shred -u -z -n 1`) before the directory node is unlinked.

### D. Resource Controls & Limits
* Maximum virtual memory (`ulimit -v`) and process concurrency caps (`ulimit -u`) prevent fork-bombs and memory exhaustion denial-of-service.

### E. Workspace Lifecycle & Cleanup
* Workspaces transition through strictly tracked states: `CREATING` -> `RUNNING` -> `STOPPING` -> `DESTROYED`.
* Orphaned, disconnected, or crashed containers are automatically reaped by the background `veil-cleanup` daemon.

### F. Session Management
* `veil-session` oversees the system lifecycle, guaranteeing all active sandboxes are stopped, volatile memory is purged, and encrypted persistent storage is locked upon logout or shutdown.
