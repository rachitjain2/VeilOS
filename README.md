# VEILOS — Disposable Computing Operating System

> Applications are guests, not owners.

VEILOS is a privacy-oriented, amnesic Linux-based live operating system prototype designed around the concept of **Disposable Computing**.

## Core Concept
- Every application launches inside a dedicated, isolated, temporary workspace.
- Applications never receive persistent personal files, hardware peripherals, or storage by default.
- Data persistence is explicit via an encrypted Secure Vault.
- Destroying a workspace wipes its temporary state from memory.

## Architecture
- **Base OS:** Debian 12 (Bookworm) Live with Linux 6.x
- **Isolation Engine:** Bubblewrap (wrap) + unprivileged Linux namespaces + tmpfs
- **Desktop Environment:** Minimal XFCE4 / Openbox privacy profile
- **Session Layer:** VEILOS Session Manager & Privacy Center (Python 3 + GTK 3)
- **Controlled Persistence:** LUKS2 dm-crypt Encrypted Vault
