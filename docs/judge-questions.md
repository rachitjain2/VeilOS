# VEILOS Hackathon Judge Q&A Guide

Technically precise, honest, 20-second answers for judges.

---

### 1. "What is VEILOS?"
> *"VEILOS is a live, disposable Linux operating system built for ephemeral computing. It runs entirely in RAM, isolates applications in unprivileged kernel namespaces, and cryptographically shreds temporary storage upon exit."*

### 2. "Isn't this just Tails?"
> *"Tails focuses primarily on network anonymity by forcing all traffic through Tor. VEILOS focuses on application-level process, filesystem, and memory isolation—allowing normal high-speed internet while preventing applications from accessing personal files or persisting artifacts."*

### 3. "Isn't this just Docker?"
> *"Docker is a server-side container runtime requiring a privileged daemon and root access to manage images. VEILOS uses unprivileged Bubblewrap namespaces integrated directly into a consumer desktop environment with zero daemon overhead."*

### 4. "Isn't this just a VM?"
> *"Virtual machines incur 10x memory and CPU overhead because they emulate full virtual hardware and run duplicate OS kernels. VEILOS provides native bare-metal hardware performance by using kernel namespaces and cgroups directly on the host kernel."*

### 5. "How is this different from a cloud PC?"
> *"Cloud PCs stream screen pixels over the internet, introduce latency, require subscriptions, and store your data on remote corporate servers. VEILOS runs 100% locally on your own hardware with zero telemetry and zero cloud dependency."*

### 6. "How does application isolation work?"
> *"We leverage Linux Bubblewrap to instantiate unshared user, mount, PID, IPC, and UTS namespaces. All host personal paths are masked, system paths are mounted read-only, and the application's home directory is bound to a volatile tmpfs in RAM."*

### 7. "What happens when I destroy a workspace?"
> *"All child processes in the container are terminated with SIGTERM and SIGKILL. All temporary files in RAM are scrubbed using cryptographic shredding (`shred -u -z`), the directory is unmounted, and the metadata registry is unlinked."*

### 8. "Can the app access my personal files?"
> *"No. In the sandbox mount table, host `/home` and personal storage are completely unmounted. The application only sees its own dedicated ephemeral directory in volatile RAM."*

### 9. "Can the application escape?"
> *"Applications execute with all Linux capabilities dropped (`--cap-drop ALL`) in an unprivileged user namespace without root access. Escaping would require an unpatched Linux kernel 0-day vulnerability."*

### 10. "Can the cloud see my data?"
> *"No. VEILOS has zero telemetry, zero analytics, and zero cloud backends. All audit logs and session metadata are stored locally in volatile RAM and destroyed on session shutdown."*

### 11. "Why would people use this?"
> *"For testing untrusted code, opening suspicious attachments, confidential web research, and privacy-sensitive development where users do not want forensic traces left on their primary machine."*

### 12. "What is actually innovative?"
> *"Bringing ephemeral computing from cloud infrastructure down to an intuitive, zero-configuration consumer live OS with transparent, real-time security proof and cryptographic destruction."*

### 13. "What is your biggest limitation?"
> *"Our prototype currently uses an X11 display server, which allows potential cross-window event observation between X clients. We disclose this transparently in our Privacy Center, with a Wayland nested compositor roadmap planned for v2.0."*
