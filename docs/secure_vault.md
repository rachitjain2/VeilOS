# VEILOS SECURE VAULT

> **Core Philosophy:** VEILOS is temporary by default, but users may explicitly choose data that they want to preserve.

The **VEILOS Secure Vault** provides controlled, explicit persistence on top of an otherwise completely amnesic live operating system.

---

## 1. Architectural & Cryptographic Foundation

VEILOS relies strictly on established, battle-tested Linux cryptographic subsystems:
* **Subsystem:** Linux kernel `dm-crypt` subsystem via `cryptsetup` (LUKS2 format).
* **Cipher:** `aes-xts-plain64` with 512-bit key size (AES-256 in XTS mode) and Argon2id key derivation function (KDF) to prevent brute-force attacks.
* **Filesystem:** Standard journaled ext4 mounted with `nosuid,nodev` options.
* **Mount Point:** `/media/veilos-vault`

---

## 2. Security Boundaries & Protection Model

### What IS Encrypted:
* All files, directories, code, and documents placed inside the unlocked Vault directory (`/media/veilos-vault`).
* Sector-level full disk encryption covering data blocks, metadata, and directory hierarchies on the backing storage device or image file (`.img`).

### Where the Key Comes From:
* **User Passphrase:** The encryption key is derived directly from the user's master passphrase entered during the unlock action.
* **Kernel Keyring:** The master key is held exclusively in volatile kernel memory (`dm-crypt` mapping in RAM). No encryption keys, salts, or passphrases are ever written to disk.

### What Happens When the Vault is Locked:
1. Pending filesystem writes are flushed to disk with `sync`.
2. Any open processes accessing `/media/veilos-vault` are terminated via `fuser -km`.
3. The filesystem is unmounted (`umount /media/veilos-vault`).
4. The device mapper target is closed (`cryptsetup luksClose`).
5. **Key Eviction:** The master key is purged and evicted from the Linux kernel memory. The backing device returns to raw ciphertext.

### What Happens During System Shutdown / Reboot:
* Systemd executes unmount and cryptsetup teardown services.
* Because the live OS runs entirely from volatile RAM (tmpfs), all RAM holding temporary keys or caches is de-energized and cleared on power-off.

### What is NOT Protected (Explicit Limitations):
* **Files left outside the vault:** Files saved to `~/Desktop`, `/tmp`, or inside unexported workspaces are not saved to the vault and disappear upon session termination.
* **Malware in an explicitly granted workspace:** If a user deliberately copies a file from the vault into an untrusted sandbox, that sandbox can inspect that individual file.
* **Compromised passphrases:** If an adversary obtains the user's master passphrase, LUKS2 cannot prevent decryption.
* **Hardware side-channels / Cold boot attacks:** In-memory encryption keys held in hardware DRAM during an active unlocked session can theoretically be vulnerable to physical cold-boot attacks prior to locking.

---

## 3. Sandboxing Policy (No Automatic Persistence)

Disposable sandboxes launched by `veil-run` (Private Browser, Developer Workspace, App Testing) **do NOT mount the Secure Vault by default**.
* An application inside a sandbox cannot discover or modify files in `/media/veilos-vault`.
* To persist a file, the user must explicitly shuttle that file using the VEILOS File Manager or copy it to the vault mount point.