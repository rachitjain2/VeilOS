#!/bin/bash
# ==============================================================================
# VEILOS Test Suite: Security Audit Hardening Verification
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_RUN="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veil-run"
SUDOERS="${SCRIPT_DIR}/../config/includes.chroot/etc/sudoers.d/veilos"
APP_TESTING="${SCRIPT_DIR}/../config/includes.chroot/etc/veilos/profiles/app-testing.json"

echo "=== [TEST 1] Verifying Capability & SUID Hardening in veil-run ==="
grep -q -- "--unshare-user" "$BIN_RUN"
grep -q -- "--cap-drop ALL" "$BIN_RUN"
grep -q -- "--new-session" "$BIN_RUN"
grep -q -- "--unsetenv DBUS_SESSION_BUS_ADDRESS" "$BIN_RUN"
echo "PASS: Capabilities dropped, user namespace isolated, new session, D-Bus unset."

echo "=== [TEST 2] Verifying Restricted Sudoers Configuration ==="
grep -q "veilos ALL=(ALL) NOPASSWD: /usr/local/bin/veilos-vault-service" "$SUDOERS"
# Check that active sudo command does not grant raw mount
if grep -v '^#' "$SUDOERS" | grep -q "bin/mount"; then
    echo "FAIL: Raw bin/mount still found in active sudoers rules!"
    exit 1
fi
echo "PASS: Sudoers strictly locked down to veilos-vault-service."

echo "=== [TEST 3] Verifying Zero-Trust Network Policy in APP_TESTING Profile ==="
grep -q '"enabled": false' "$APP_TESTING"
echo "PASS: APP_TESTING profile defaults to offline network."

echo "=== ALL SECURITY HARDENING VERIFICATION CHECKS PASSED ==="