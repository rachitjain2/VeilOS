# VEILOS Hackathon Demo Guide (2–3 Minutes)

**Core Positioning:**
> "VEILOS is a live, disposable Linux operating system built for ephemeral computing. Sandboxes are disposable by design, data is destroyed with cryptographic shredding, and security boundaries are honest—no fake security."

---

## Pre-Demo Quick Verification (Run in Background)

Before presenting, open a terminal and run the self-test:
```bash
veil-doctor
```
*Expected result:* All components show **PASS** (or WARN if running in a virtualized development environment), with `[✓] Sandbox engine: READY`.

---

## Step-by-Step Presentation Script

### 1. The Opening (30 seconds)
**Action:** Show the clean VEILOS Desktop.
**Say:**
> *"Most operating systems accumulate forensic artifacts, cache browsing histories, retain temporary files, and expose user files to running applications. VEILOS treats every computing session and every application as ephemeral by default. Applications run in unprivileged Linux namespaces with disposable storage in RAM, and every security guarantee is backed by real kernel isolation."*

---

### 2. Launching Private Browser & Transparency (45 seconds)
**Action:**
1. Click the **Private Browser** icon from the desktop or run:
   ```bash
   veil-run --profile private-browser
   ```
2. Open the **Privacy Center** (or run `veilos-privacy-center`).
**Say:**
> *"When we launch the Private Browser, VEILOS dynamically creates a dedicated ephemeral workspace in RAM (`tmpfs`). Notice what the Privacy Center reports:*
> - * **Filesystem Isolation:** Enforced (User personal files are unmounted and completely blocked).*
> - * **Storage:** Temporary (Session profile discarded upon exit).*
> - * **Honest Policy Disclosure:** We honestly report network status (Internet ALLOWED) and disclose known architectural boundaries such as shared X11 access under Xorg, with Wayland isolation planned for future builds.*
> - * **Audit Logging:** Every sandbox creation, process spawn, and destruction is logged locally without recording personal URLs, keystrokes, or sensitive payloads."*

---

### 3. Destruction Proof (45 seconds)
**Action:**
1. Show an active workspace ID in the terminal:
   ```bash
   veil-run --list
   ```
2. Click **Destroy Workspace** in the desktop launcher UI or run:
   ```bash
   veil-run --destroy <workspace-id>
   ```
3. Point out the terminal logs showing verification:
   - `[DESTROY_REQUESTED]`
   - Terminating all child PIDs with `SIGTERM` / `SIGKILL`
   - Shredding ephemeral workspace files (`shred -u -z`)
   - Unlinking active registry
   - Verification stage checking directory is gone
   - Performance timing log (`[PERF] Workspace destroyed in 1s`)
4. Show that trying to access the destroyed workspace is strictly rejected.
**Say:**
> *"In VEILOS, STOP and DESTROY are distinct operations. STOP pauses execution, but DESTROY purges the sandbox, shreds ephemeral files, terminates all child processes, and unlinks the registration. As you can see, accessing the destroyed workspace returns an immediate access denial."*

---

### 4. Multi-Workspace Isolation (30 seconds)
**Action:**
Run the automated isolation test:
```bash
tests/isolation-test.sh
```
**Say:**
> *"VEILOS enforces strict multi-workspace isolation. Here, we run two simultaneous workspaces (Workspace A and Workspace B). Destroying Workspace A shreds its data and kills its processes, while Workspace B continues uninterrupted with zero data leakage or shared memory bleeding."*

---

### 5. Ending the Session (30 seconds)
**Action:**
Click **End Session** on the desktop or run:
```bash
veil-session --stop
```
**Say:**
> *"When a session ends, the VEILOS Session Manager reaps all active sandboxes, scrubs uncommitted volatile memory, locks encrypted storage, and halts. What happens in VEILOS stays in that session."*

---

## Demo Backup & Fallback Plan

| Potential Issue | Quick Fallback Action |
| :--- | :--- |
| Stale or lingering test workspaces from earlier runs | Run `veil-demo-reset`. This cleans only VEILOS test RAM dirs without affecting system processes. |
| X11 display resolution mismatch in VM/QEMU | VEILOS Desktop automatically defaults to 1024x768 / 1920x1080 standard X11 viewport. |
| Offline / No internet connection during judging | All core profiles, tests, mock runners, and tools work 100% offline without external network dependencies. |
| Judge asks: *"Is X11 completely secure against keylogging?"* | Answer honestly: *"No. Under X11, any X client can monitor events. We explicitly document this limitation in our Privacy Center and architecture specification, and our roadmap migrates to Wayland nested compositors."* |
