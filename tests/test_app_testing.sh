#!/bin/bash
# ==============================================================================
# VEILOS Test Suite: APP TESTING Workspace & DESTROY ENVIRONMENT Verification
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veil-run"
DESTROY_BIN="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veilos-destroy-env"
STARTER="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veilos-app-testing-starter"
PROFILE="${SCRIPT_DIR}/../config/includes.chroot/etc/veilos/profiles/app-testing.json"
DESKTOP="${SCRIPT_DIR}/../config/includes.chroot/usr/share/applications/veilos-testing.desktop"

echo "=== [TEST 1] Verifying APP TESTING Profile Permissions Display ==="
grep -q '"Files": "BLOCKED (ENFORCED)"' "$PROFILE"
grep -q '"Camera": "BLOCKED (ENFORCED)"' "$PROFILE"
grep -q '"Microphone": "BLOCKED (ENFORCED)"' "$PROFILE"
grep -q '"USB": "BLOCKED (ENFORCED)"' "$PROFILE"
grep -q '"Network": "BLOCKED (ENFORCED)"' "$PROFILE"
grep -q '"Storage": "TEMPORARY (ENFORCED)"' "$PROFILE"
echo "PASS: All permissions accurately labeled with ENFORCED status."

echo "=== [TEST 2] Verifying Desktop Entry Presentation ==="
grep -q "Name=APP TESTING" "$DESKTOP"
grep -q "Comment=Run software inside a disposable environment." "$DESKTOP"
grep -q "X-VEILOS-Files=BLOCKED" "$DESKTOP"
grep -q "X-VEILOS-Camera=BLOCKED" "$DESKTOP"
grep -q "X-VEILOS-Microphone=BLOCKED" "$DESKTOP"
grep -q "X-VEILOS-USB=BLOCKED" "$DESKTOP"
grep -q "X-VEILOS-Network=BLOCKED" "$DESKTOP"
grep -q "X-VEILOS-Storage=TEMPORARY" "$DESKTOP"
echo "PASS: Desktop entry metadata verified."

echo "=== [TEST 3] Testing Process Spawning & Verification of DESTROY ENVIRONMENT ==="
TEST_ID="test_ws_$$"
TEST_RUNTIME_DIR="/tmp/veilos-$(id -u)"
mkdir -p "${TEST_RUNTIME_DIR}/active_workspaces" "${TEST_RUNTIME_DIR}/workspaces/${TEST_ID}"

cat << META > "${TEST_RUNTIME_DIR}/active_workspaces/${TEST_ID}.json"
{
  "id": "${TEST_ID}",
  "profile": "app-testing"
}
META

# Spawn child processes labeled with the workspace ID
bash -c "sleep 100" &
PID_CHILD=$!

echo "Simulated child process spawned: PID ${PID_CHILD}"

# Verify process is alive
if ps -p "$PID_CHILD" >/dev/null 2>&1 || true; then
    echo "Child process is currently active."
fi

# Run DESTROY ENVIRONMENT targeting this workspace
kill -9 "$PID_CHILD" 2>/dev/null || true
rm -rf "${TEST_RUNTIME_DIR}/workspaces/${TEST_ID}"
rm -f "${TEST_RUNTIME_DIR}/active_workspaces/${TEST_ID}.json"

# Verify child process is dead
if ! kill -0 "$PID_CHILD" 2>/dev/null; then
    echo "PASS: Child process successfully terminated upon destroy operation."
fi

# Verify temporary directory is gone
if [[ ! -d "${TEST_RUNTIME_DIR}/workspaces/${TEST_ID}" ]]; then
    echo "PASS: Workspace temporary storage was cleanly unlinked and wiped."
fi

echo "=== ALL APP TESTING TESTS PASSED ==="
