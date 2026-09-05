# VEILOS Application Sandbox Service: `veil-run`

The `veil-run` service is the central application gateway of VEILOS. It enforces the core philosophy: **"Applications are guests, not owners."**

## Architectural Flow

```
VEILOS UI (Dashboard / Menus)
          │
          ▼
       veil-run
          │
          ▼
Security Policy (/etc/veilos/profiles/*.json)
          │
          ▼
Bubblewrap Sandbox (bwrap namespaces + cgroups)
          │
          ▼
Application (firefox-esr, mousepad, xfce4-terminal, etc.)
```

---

## Technical Isolation Mechanisms

| Dimension | Mechanism | Security Property |
| :--- | :--- | :--- |
| **Filesystem** | Bubblewrap unprivileged mount namespace | System paths (`/usr`, `/lib`, `/etc`, `/bin`) are strictly **Read-Only**. Host home directory is masked by an ephemeral `tmpfs` workspace in RAM. |
| **Network** | Network namespace (`--unshare-net`) | When disabled, applications see only a local loopback device with no outbound networking. |
| **Process** | PID & IPC namespaces | Applications cannot inspect or signal processes running outside their designated workspace. |
| **Volatile Memory** | Session scrubbing hook | On exit or termination, all files in the workspace are overwritten with `shred` before unmounting. |
| **Resources** | Virtual memory quotas | Enforces maximum memory footprint per profile. |

---

## Predefined Profiles

### 1. `private-browser`
* **Executable:** `/usr/bin/firefox-esr`
* **Network:** Allowed (`--ro-bind /etc/resolv.conf`)
* **Storage:** Ephemeral `tmpfs`
* **Host Files:** Completely masked
* **Audio:** Allowed

### 2. `development`
* **Executable:** `/usr/bin/mousepad`
* **Network:** Denied (`--unshare-net`)
* **Storage:** Ephemeral `tmpfs`
* **Host Files:** Completely masked

### 3. `app-testing`
* **Executable:** `/usr/bin/xfce4-terminal`
* **Network:** Denied (`--unshare-net`)
* **Storage:** Ephemeral `tmpfs`
* **Host Files:** Completely masked
* **Resource Limit:** 1024 MB RAM

---

## Usage Examples

```bash
# List all available profiles
veil-run --list-profiles

# Launch a profile
veil-run --profile private-browser
veil-run --profile development
veil-run --profile app-testing

# Dry-run inspection
veil-run --profile app-testing --dry-run
```

---

## Audit Logs

All lifecycle transitions are recorded in real-time to `$XDG_RUNTIME_DIR/veilos-$UID/logs/veil-run.log`:
- `[WORKSPACE_CREATED]`
- `[APPLICATION_STARTED]`
- `[APPLICATION_STOPPED]`
- `[WORKSPACE_DESTROYED]`