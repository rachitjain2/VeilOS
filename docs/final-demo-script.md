# VEILOS Final Hackathon Demo Script (2–3 Minutes)

**Presenter Goal:** Deliver a crisp, technical, proof-driven demonstration of VEILOS for hackathon judges.

---

## 1. Opening (0:00 – 0:25)
> *"Every application we install asks us to trust our device with it. Browsers store tracking cookies, scratch scripts read home directories, and experimental software can compromise system stability.*
>
> *What if applications were guests instead of owners?*
>
> *This is VEILOS: a live, disposable Linux operating system designed for ephemeral computing. Sandboxes are disposable by design, data is destroyed with cryptographic shredding, and security boundaries are honest—no fake security."*

---

## 2. Problem & Solution (0:25 – 0:50)
> *"On traditional operating systems, applications have direct access to your personal files, background network sockets, and persistent disk storage.*
>
> *VEILOS changes the paradigm: every computing session and every application is ephemeral by default. Workspaces run in isolated Linux namespaces created by Bubblewrap with volatile RAM tmpfs storage. When you destroy a workspace or shut down, your data isn't just closed—it's shredded."*

---

## 3. Live Demo: Private Browser (0:50 – 1:30)
**Action:** Click the **Private Browser** icon from the desktop (or run `veil-run --profile private-browser`).
**Say:**
> *"Let's launch the Private Browser. Notice the pre-flight policy screen that appears before execution:*
> - * **Application:** Chromium / Firefox*
> - * **Environment:** Isolated Ephemeral Workspace in RAM*
> - * **Permissions:** Internet ALLOWED, Local Files BLOCKED, Camera/Mic BLOCKED, Storage TEMPORARY.*
>
> *The sandbox initializes: unprivileged user namespace, PID namespace, IPC isolation, and dropped Linux capabilities. The browser is now live, isolated from the host system."*

---

## 4. Privacy Proof: Privacy Center (1:30 – 2:05)
**Action:** Open the **Privacy Center** (or run `veilos-privacy-center`).
**Say:**
> *"Next, we open the VEILOS Privacy Center—our live proof screen. The judge can immediately inspect the active workspace telemetry:*
> - * **Application:** Browser (Running)*
> - * **Workspace ID:** Dedicated unique runtime identifier*
> - * **Filesystem:** ENFORCED (Host personal files strictly masked)*
> - * **Storage:** VOLATILE RAM (Purged on destroy)*
> - * **Live Session Duration:** Real-time active counter*
>
> *Notice our honest architecture disclosures below: we state plainly that X11 display architecture is a prototype limitation with Wayland nested compositors planned for our next release, and network policy is enforced at the profile level."*

---

## 5. Destruction Proof (2:05 – 2:40)
**Action:** Click **Destroy Workspace** in the Privacy Center (or run `veil-run --destroy <workspace-id>`).
**Say:**
> *"In VEILOS, STOP and DESTROY are completely different operations. Watch what happens when I click Destroy:*
> - * **Status:** STOPPING...*
> - * All child processes receive SIGTERM and SIGKILL.*
> - * All ephemeral files in RAM are scrubbed with cryptographic shredding (`shred -u -z`).*
> - * Active workspace registration is unlinked.*
> - * **Result:** ✓ WORKSPACE DESTROYED | RUNTIME: NOT FOUND | ACCESS: DENIED.*
>
> *If an attacker or script tries to access that workspace ID again, the system immediately returns an access denial."*

---

## 6. Closing (2:40 – 3:00)
> *"VEILOS proves that ephemeral computing is not just for cloud servers—it belongs on personal devices. Disposable environments, cryptographic destruction, and total transparency.*
>
> *Thank you, judges. We welcome your questions."*
