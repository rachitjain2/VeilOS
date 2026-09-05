# VEILOS SESSION MANAGER & CLEANUP SPECIFICATION

VEILOS treats every boot cycle and live session as **temporary by default**.

---

## 1. Responsibilities of `veil-session`

1. **Session Initialization:** Records boot timestamp, generates unique session ID, and provisions volatile runtime state in RAM (`tmpfs`).
2. **Telemetry & Tracking:** Tracks active sandbox instances, running guest processes, and persistent storage mount status.
3. **Session Teardown (`END SESSION`):**
   - Signals and terminates all unprivileged Bubblewrap (`bwrap`) containers.
   - Kills guest application processes (`firefox-esr`, `geany`, `xfce4-terminal`, etc.).
   - Issues `sync` and unmounts the encrypted Secure Vault (`veilos-vault-service lock`), evicting master encryption keys from kernel memory.
   - Overwrites and shreds temporary workspace directories in memory (`shred -u -z -n 1`).
   - Closes session records and triggers desktop logout or machine poweroff.

---

## 2. Actual Cleanup Performed vs Limitations

### What IS Cleaned Up:
* **All active sandboxes:** Process trees (`PID` namespaces) running under `veil-run` are sent `SIGKILL`.
* **Temporary files in RAM:** All files stored in `/run/user/$UID/veilos/workspaces/*` are overwritten and deleted.
* **Encrypted Vault:** The LUKS persistent volume is safely unmounted and closed; cached cryptographic keys in the Linux kernel keyring are evicted.
* **Live session state:** Browser cookies, temporary downloads, cache files, and shell histories accumulated inside sandboxes evaporate.

### Forensic Limitations (What is NOT Claimed):
* **No "Zero Forensic Trace" Guarantee:** VEILOS does not claim complete immunity against hardware physical probing, firmware NVRAM modifications, or physical cold-boot memory remanence attacks before power-off.
* **Unencrypted Swap Warning:** VEILOS does not mount or create persistent swap partitions, but if booted on a system with existing swap partitions enabled without encryption, memory pages could theoretically leak. (VEILOS disables automatic swap mounting by default).
* **Firmware/BIOS:** Attacks targeting CPU microcode or BIOS/UEFI state are outside the software threat model.