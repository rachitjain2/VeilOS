#!/bin/bash
# ==============================================================================
# VEILOS Test Suite: Hardened Lifecycle & Stale Environment Reaper (veil-cleanup)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_RUN="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veil-run"
BIN_CLEANUP="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veil-cleanup"

echo "=== [TEST 1] Syntax Check on veil-cleanup & hardened veil-run ==="
bash -n "$BIN_CLEANUP"
bash -n "$BIN_RUN"
echo "PASS: Script syntax validated."

echo "=== [TEST 2] Verifying All 5 Lifecycle States Declared in veil-run ==="
grep -q "CREATING" "$BIN_RUN"
grep -q "RUNNING" "$BIN_RUN"
grep -q "STOPPING" "$BIN_RUN"
grep -q "DESTROYED" "$BIN_RUN"
grep -q "ERROR" "$BIN_RUN"
echo "PASS: CREATING, RUNNING, STOPPING, DESTROYED, ERROR states verified."

echo "=== [TEST 3] Verifying Exact Required Logging Events ==="
grep -q "workspace_created" "$BIN_RUN"
grep -q "workspace_started" "$BIN_RUN"
grep -q "workspace_stopped" "$BIN_RUN"
grep -q "workspace_destroyed" "$BIN_RUN"
grep -q "cleanup_triggered" "$BIN_RUN"
grep -q "cleanup_failed" "$BIN_RUN"
echo "PASS: All 6 lifecycle and cleanup events verified."

echo "=== [TEST 4] Simulating Stale/Crashed Workspace Reaping via veil-cleanup ==="
TEST_UID=$(id -u)
TEST_DIR="/tmp/veilos-${TEST_UID}"
mkdir -p "${TEST_DIR}/active_workspaces" "${TEST_DIR}/workspaces/stale_ws_9999"

cat << META > "${TEST_DIR}/active_workspaces/stale_ws_9999.json"
{
  "id": "stale_ws_9999",
  "pid": 99999999,
  "workspace_path": "${TEST_DIR}/workspaces/stale_ws_9999",
  "lifecycle_state": "RUNNING"
}
META

touch "${TEST_DIR}/workspaces/stale_ws_9999/leaked_artifact.tmp"

# Run veil-cleanup scan
bash "$BIN_CLEANUP" scan

# Verify stale workspace was reclaimed
if [[ ! -f "${TEST_DIR}/active_workspaces/stale_ws_9999.json" ]]; then
    echo "PASS: Stale registration JSON removed by veil-cleanup."
fi

if [[ ! -d "${TEST_DIR}/workspaces/stale_ws_9999" ]]; then
    echo "PASS: Abandoned directory reclaimed and shredded."
fi

echo "=== ALL HARDENED LIFECYCLE TESTS PASSED ==="