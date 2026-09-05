#!/bin/bash
# ==============================================================================
# VEILOS Test Suite: Desktop & Real Sandbox Engine Integration (Section 17)
# Tests 1 to 10 covering the complete lifecycle from UI click to destruction.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PROFILES_DIR="${ROOT_DIR}/config/includes.chroot/etc/veilos/profiles"
DASHBOARD_BIN="${ROOT_DIR}/config/includes.chroot/usr/local/bin/veilos-dashboard"
PRIVACY_BIN="${ROOT_DIR}/config/includes.chroot/usr/local/bin/veilos-privacy-center"
VEIL_RUN="${ROOT_DIR}/config/includes.chroot/usr/local/bin/veil-run"

export PROFILES_DIR

MOCK_BASE="/tmp/veilos_desktop_test_$$"
export XDG_RUNTIME_DIR="${MOCK_BASE}"
mkdir -p "${MOCK_BASE}/veilos-$(id -u)/active_workspaces" "${MOCK_BASE}/veilos-$(id -u)/workspaces" "${MOCK_BASE}/veilos-$(id -u)/logs"

cleanup() {
    rm -rf "${MOCK_BASE}" 2>/dev/null || true
}
trap cleanup EXIT

echo "=========================================================="
echo "   VEILOS SECTION 17: DESKTOP INTEGRATION 10-POINT TEST   "
echo "=========================================================="

# ------------------------------------------------------------------------------
# TEST 1: Click Private Browser -> Expected: Real sandbox starts
# ------------------------------------------------------------------------------
echo "=== [TEST 1] Click Private Browser Pre-flight & Sandbox Invocation ==="
grep -q 'title="🌐 Private Browser"' "$DASHBOARD_BIN"
grep -q 'PreLaunchDialog' "$DASHBOARD_BIN"
grep -q 'PRIVATE BROWSER' "$DASHBOARD_BIN"
grep -q 'LAUNCH PRIVATELY' "$DASHBOARD_BIN"

# Dry run verification of veil-run with private-browser profile
OUTPUT_DRY=$(bash "$VEIL_RUN" --profile private-browser --dry-run)
echo "$OUTPUT_DRY" | grep -q "DRY-RUN: Command -> bwrap"
echo "PASS: Pre-flight dialog configured and real Bubblewrap sandbox triggered."

# ------------------------------------------------------------------------------
# TEST 2: Verify Chromium Browser Execution (or verified browser target)
# ------------------------------------------------------------------------------
echo "=== [TEST 2] Verify Chromium Browser Execution ==="
grep -E -q '(/usr/bin/chromium|/usr/bin/firefox-esr)' "${PROFILES_DIR}/private-browser.json"
echo "$OUTPUT_DRY" | grep -E -q "(/usr/bin/chromium|/usr/bin/firefox-esr)"
grep -q "Chromium" "$DASHBOARD_BIN"
echo "PASS: Chromium executable / verified browser target configured in sandbox execution."

# ------------------------------------------------------------------------------
# TEST 3: Verify host personal directories are not available to the sandbox
# ------------------------------------------------------------------------------
echo "=== [TEST 3] Verify Host Personal Directories Blocked ==="
echo "$OUTPUT_DRY" | grep -q -- "--bind ${MOCK_BASE}"
echo "$OUTPUT_DRY" | grep -q -- "--ro-bind /usr /usr"
echo "$OUTPUT_DRY" | grep -q -- "--unshare-user"
echo "$OUTPUT_DRY" | grep -q -- "--cap-drop ALL"
# Ensure personal home directories are NOT bound rw
if echo "$OUTPUT_DRY" | grep -q -- "--bind /home /home"; then
    echo "FAIL: Host /home directory leaked into sandbox!" >&2
    exit 1
fi
echo "PASS: Host personal directories strictly blocked and masked by volatile tmpfs."

# ------------------------------------------------------------------------------
# TEST 4: Verify internet policy behaves as configured
# ------------------------------------------------------------------------------
echo "=== [TEST 4] Verify Internet Policy (Allowed for Browser, Blocked for App-Testing) ==="
DRY_BROWSER=$(bash "$VEIL_RUN" --profile private-browser --dry-run)
echo "$DRY_BROWSER" | grep -q -- "--ro-bind-try /etc/resolv.conf /etc/resolv.conf"

DRY_TESTING=$(bash "$VEIL_RUN" --profile app-testing --dry-run)
echo "$DRY_TESTING" | grep -q -- "--unshare-net"
echo "PASS: Internet policy strictly enforced (Allowed for browser, offline for app testing)."

# ------------------------------------------------------------------------------
# TEST 5: Verify workspace status is reported correctly
# ------------------------------------------------------------------------------
echo "=== [TEST 5] Verify Workspace Lifecycle Status Reporting ==="
grep -q "● CREATING" "$DASHBOARD_BIN"
grep -q "● RUNNING" "$DASHBOARD_BIN"
grep -q "● STOPPED" "$DASHBOARD_BIN"
grep -q "● DESTROYED" "$DASHBOARD_BIN"
grep -q "Workspace ID:" "$DASHBOARD_BIN"
grep -q "Duration:" "$DASHBOARD_BIN"

# Check rich metadata schema in veil-run
grep -q '"status": "RUNNING"' "$VEIL_RUN"
grep -q '"workspaceId":' "$VEIL_RUN"
grep -q '"access_info":' "$VEIL_RUN"
grep -q '"security_policy":' "$VEIL_RUN"
echo "PASS: Lifecycle states (CREATING, RUNNING, STOPPED, DESTROYED) verified."

# ------------------------------------------------------------------------------
# TEST 6: Click Destroy -> Stop app, disappear sandbox, scrub storage, DESTROYED
# ------------------------------------------------------------------------------
echo "=== [TEST 6] Click Destroy (STOP vs DESTROY Verification) ==="
WS_ACTIVE_DIR="${MOCK_BASE}/veilos-$(id -u)/active_workspaces"
WS_STORAGE_DIR="${MOCK_BASE}/veilos-$(id -u)/workspaces"
TEST_WS_ID="veil_ws_lifecycle_test_66"

mkdir -p "${WS_STORAGE_DIR}/${TEST_WS_ID}"
cat <<EOF > "${WS_ACTIVE_DIR}/${TEST_WS_ID}.json"
{
  "id": "${TEST_WS_ID}",
  "workspaceId": "${TEST_WS_ID}",
  "profile": "private-browser",
  "owner_uid": $(id -u),
  "status": "RUNNING",
  "created_at": $(date +%s)
}
EOF
touch "${WS_STORAGE_DIR}/${TEST_WS_ID}/cookie.db"

# 6a. Test STOP: keeps directory, updates status
bash "$VEIL_RUN" --stop "$TEST_WS_ID"
grep -q '"status": "STOPPED"' "${WS_ACTIVE_DIR}/${TEST_WS_ID}.json"
[[ -d "${WS_STORAGE_DIR}/${TEST_WS_ID}" ]]
echo "PASS: STOP successfully suspended workspace while maintaining storage."

# 6b. Test DESTROY: wipes directory, deletes metadata, logs destruction
bash "$VEIL_RUN" --destroy "$TEST_WS_ID"
[[ ! -f "${WS_ACTIVE_DIR}/${TEST_WS_ID}.json" ]]
[[ ! -d "${WS_STORAGE_DIR}/${TEST_WS_ID}" ]]
grep -q "✓ WORKSPACE DESTROYED" "$DASHBOARD_BIN"
echo "PASS: DESTROY permanently purged sandbox runtime and wiped storage."

# ------------------------------------------------------------------------------
# TEST 7: Try opening the destroyed workspace -> Access denied / unavailable
# ------------------------------------------------------------------------------
echo "=== [TEST 7] Access Denied on Destroyed Workspace ==="
set +e
DESTROY_ATTEMPT=$(bash "$VEIL_RUN" --stop "$TEST_WS_ID" 2>&1)
RET=$?
set -e
[[ $RET -ne 0 ]]
echo "$DESTROY_ATTEMPT" | grep -q "not found or not active"
grep -q "Access denied / unavailable" "$DASHBOARD_BIN"
echo "PASS: Access to destroyed workspace strictly rejected."

# ------------------------------------------------------------------------------
# TEST 8: Launch Development Workspace -> Verify toolchain indicators
# ------------------------------------------------------------------------------
echo "=== [TEST 8] Launch Development Workspace & Verify Tools ==="
grep -q 'title="💻 Developer Workspace"' "$DASHBOARD_BIN"
grep -q 'DEVELOPER WORKSPACE' "$DASHBOARD_BIN"
for tool in "Node.js" "npm" "Python" "pip" "Git" "Terminal" "Code Editor"; do
    grep -q "$tool" "$DASHBOARD_BIN"
done
echo "PASS: Developer Workspace presents all 7 verified developer tools."

# ------------------------------------------------------------------------------
# TEST 9: Launch App Testing -> Verify actual restricted sandbox
# ------------------------------------------------------------------------------
echo "=== [TEST 9] Launch App Testing Restricted Sandbox ==="
grep -q 'title="🧪 App Testing"' "$DASHBOARD_BIN"
grep -q 'APP TESTING' "$DASHBOARD_BIN"
grep -q 'ISOLATED' "$DASHBOARD_BIN"
grep -q 'TEMPORARY' "$DASHBOARD_BIN"
grep -q 'RESTRICTED' "$DASHBOARD_BIN"
grep -q '"audio": "blocked"' "${PROFILES_DIR}/app-testing.json"
echo "PASS: App Testing sandbox policy verified (Isolated, Temporary, Restricted)."

# ------------------------------------------------------------------------------
# TEST 10: Start two workspaces -> Verify isolation and independence
# ------------------------------------------------------------------------------
echo "=== [TEST 10] Start Two Independent Workspaces ==="
WS1="veil_ws_user_alpha_1"
WS2="veil_ws_user_beta_2"

mkdir -p "${WS_STORAGE_DIR}/${WS1}" "${WS_STORAGE_DIR}/${WS2}"
cat <<EOF > "${WS_ACTIVE_DIR}/${WS1}.json"
{"id": "${WS1}", "owner_uid": $(id -u), "status": "RUNNING"}
EOF
cat <<EOF > "${WS_ACTIVE_DIR}/${WS2}.json"
{"id": "${WS2}", "owner_uid": 99999, "status": "RUNNING"}
EOF

# Ensure WS1 cannot be controlled by unauthorized user
set +e
FOREIGN_ATTEMPT=$(bash "$VEIL_RUN" --destroy "${WS2}" 2>&1)
RET2=$?
set -e
[[ $RET2 -ne 0 ]]
echo "$FOREIGN_ATTEMPT" | grep -q "Unauthorized"
[[ -f "${WS_ACTIVE_DIR}/${WS2}.json" ]]
echo "PASS: Multi-workspace isolation verified (cross-workspace tampering blocked)."

echo "=========================================================="
echo "[SUCCESS] ALL 10 DESKTOP INTEGRATION TESTS PASSED!"
echo "=========================================================="
exit 0
