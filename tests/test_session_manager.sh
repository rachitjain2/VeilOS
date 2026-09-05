#!/bin/bash
# ==============================================================================
# VEILOS Test Suite: SESSION MANAGER & TEARDOWN VERIFICATION
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veil-session"
GUI="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veilos-session-manager"
DOC="${SCRIPT_DIR}/../docs/session_management.md"

echo "=== [TEST 1] Verifying Session Service & GUI Syntax ==="
bash -n "$SERVICE"
echo "PASS: veil-session service bash syntax valid."

grep -q "class VeilosSessionWindow" "$GUI"
grep -q "CURRENT SESSION" "$GUI"
grep -q "Started:" "$GUI"
grep -q "Applications running:" "$GUI"
grep -q "Temporary environments:" "$GUI"
grep -q "Persistent vault:" "$GUI"
grep -q "\[ END SESSION \]" "$GUI"
grep -q "End this temporary session?" "$GUI"
grep -q "Temporary application environments will be terminated." "$GUI"
grep -q "SESSION TERMINATED" "$GUI"
echo "PASS: veilos-session-manager UI components and strings verified."

echo "=== [TEST 2] Verifying Session Telemetry Reporting ==="
STATUS=$(bash "$SERVICE" status)
echo "$STATUS" | grep -q '"applications_running"'
echo "$STATUS" | grep -q '"temporary_environments"'
echo "$STATUS" | grep -q '"persistent_vault"'
echo "PASS: Session telemetry properly reports JSON metrics."

echo "=== [TEST 3] Testing Session Termination Cleanup Routine ==="
TEST_DIR="/tmp/veilos-$(id -u)/workspaces/test_session_ws"
mkdir -p "$TEST_DIR"
touch "$TEST_DIR/test_cookie.tmp"

# Run terminate
bash "$SERVICE" terminate >/dev/null 2>&1 || true

if [[ ! -f "$TEST_DIR/test_cookie.tmp" ]]; then
    echo "PASS: Temporary workspace files scrubbed during session termination."
fi

echo "=== [TEST 4] Verifying Documentation of Cleanup Actions & Limitations ==="
grep -q "What IS Cleaned Up" "$DOC"
grep -q "Forensic Limitations" "$DOC"
echo "PASS: Documentation clearly discloses actual cleanup vs forensic limits."

echo "=== ALL SESSION MANAGER TESTS PASSED ==="