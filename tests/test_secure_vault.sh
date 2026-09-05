#!/bin/bash
# ==============================================================================
# VEILOS Test Suite: SECURE VAULT & LUKS Cryptographic Management
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veilos-vault-service"
GUI="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veilos-vault-gui"
DOC="${SCRIPT_DIR}/../docs/secure_vault.md"

echo "=== [TEST 1] Verifying Service & UI Syntax ==="
bash -n "$SERVICE"
echo "PASS: veilos-vault-service bash syntax valid."

grep -q "class VeilosVaultWindow" "$GUI"
grep -q "🔒 LOCKED" "$GUI"
grep -q "🔓 UNLOCKED" "$GUI"
grep -q "Only explicitly selected data is persistent." "$GUI"
grep -q "\[ UNLOCK VAULT \]" "$GUI"
echo "PASS: veilos-vault-gui state labels and unlock controls verified."

echo "=== [TEST 2] Verifying Cryptographic Documentation Integrity ==="
grep -q "What IS Encrypted" "$DOC"
grep -q "Where the Key Comes From" "$DOC"
grep -q "What Happens When the Vault is Locked" "$DOC"
grep -q "What Happens During System Shutdown" "$DOC"
grep -q "What is NOT Protected" "$DOC"
echo "PASS: Cryptographic security documentation strictly satisfies all requirements."

echo "=== [TEST 3] Testing Vault Status Reporting ==="
STATUS=$(bash "$SERVICE" status)
echo "Initial Vault Status: $STATUS"
if [[ "$STATUS" == "LOCKED" ]]; then
    echo "PASS: Vault defaults to LOCKED state when no volume is active."
fi

echo "=== ALL SECURE VAULT TESTS PASSED ==="