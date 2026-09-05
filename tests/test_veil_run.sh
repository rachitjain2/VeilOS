#!/bin/bash
# ==============================================================================
# VEILOS Test Suite: Phase 3 veil-run & Profiles
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veil-run"
PROFILES_DIR="${SCRIPT_DIR}/../config/includes.chroot/etc/veilos/profiles"

echo "=== [TEST 1] Syntax Check on veil-run ==="
bash -n "$BIN"
echo "PASS: veil-run syntax valid"

echo "=== [TEST 2] Profile Files Existence and JSON Integrity ==="
for prof in private-browser development app-testing; do
    PFILE="${PROFILES_DIR}/${prof}.json"
    if [[ ! -f "$PFILE" ]]; then
        echo "FAIL: Missing profile $PFILE"
        exit 1
    fi
    echo -n "Validating JSON keys in ${prof}.json... "
    grep -q '"profile_id"' "$PFILE"
    grep -q '"executable"' "$PFILE"
    grep -q '"filesystem_policy"' "$PFILE"
    grep -q '"network_policy"' "$PFILE"
    grep -q '"storage_policy"' "$PFILE"
    grep -q '"resource_policy"' "$PFILE"
    echo "OK"
done

echo "=== [TEST 3] Testing veil-run Dry-Run Generation ==="
# Mock /etc/veilos/profiles by setting PROFILES_DIR in test call
bash -c "PROFILES_DIR='${PROFILES_DIR}' bash '${BIN}' --dry-run --profile private-browser"
echo "PASS: private-browser dry run succeeded"

bash -c "PROFILES_DIR='${PROFILES_DIR}' bash '${BIN}' --dry-run --profile development"
echo "PASS: development dry run succeeded"

bash -c "PROFILES_DIR='${PROFILES_DIR}' bash '${BIN}' --dry-run --profile app-testing"
echo "PASS: app-testing dry run succeeded"

echo "=== ALL PHASE 3 TESTS COMPLETED SUCCESSFULLY ==="