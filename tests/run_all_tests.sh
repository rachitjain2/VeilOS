#!/bin/bash
# ==============================================================================
# VEILOS Master Verification Suite
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo "          VEILOS MASTER VERIFICATION TEST RUN             "
echo "=========================================================="

TESTS=(
    "test_syntax.sh"
    "test_dashboard.sh"
    "test_veil_run.sh"
    "test_private_browser.sh"
    "test_dev_workspace.sh"
    "test_app_testing.sh"
    "test_secure_vault.sh"
    "test_privacy_center.sh"
    "test_session_manager.sh"
    "test_lifecycle_cleanup.sh"
    "test_security_hardening.sh"
    "test_profile_engine_15.sh"
    "test_desktop_integration.sh"
    "demo-smoke-test.sh"
    "isolation-test.sh"
)

PASSED=0
FAILED=0

for t in "${TESTS[@]}"; do
    echo ""
    echo ">>> Running $t <<<"
    if bash "${SCRIPT_DIR}/$t"; then
        echo "[PASS] $t succeeded."
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] $t failed!"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=========================================================="
echo "TEST RESULTS: ${PASSED} PASSED, ${FAILED} FAILED."
echo "=========================================================="

if [[ $FAILED -eq 0 ]]; then
    echo "[SUCCESS] All ${#TESTS[@]} VEILOS test suites verified!"
    exit 0
else
    echo "[ERROR] Some tests failed."
    exit 1
fi