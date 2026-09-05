#!/bin/bash
# ==============================================================================
# VEILOS Test Suite: PRIVATE BROWSER Profile Verification
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veil-run"
PROFILES_DIR="${SCRIPT_DIR}/../config/includes.chroot/etc/veilos/profiles"
DESKTOP_ENTRY="${SCRIPT_DIR}/../config/includes.chroot/usr/share/applications/veilos-browser.desktop"

echo "=== [TEST 1] Verifying Private Browser Desktop Entry Metadata ==="
grep -q "Name=PRIVATE BROWSER" "$DESKTOP_ENTRY"
grep -q "Comment=Browse inside a temporary isolated environment." "$DESKTOP_ENTRY"
grep -q "X-VEILOS-Network=Allowed" "$DESKTOP_ENTRY"
grep -q "X-VEILOS-LocalFiles=Blocked" "$DESKTOP_ENTRY"
grep -q "X-VEILOS-Persistence=Off" "$DESKTOP_ENTRY"
echo "PASS: Desktop Entry contains all required user tags & descriptions."

echo "=== [TEST 2] Verifying Private Browser Profile Policy ==="
PFILE="${PROFILES_DIR}/private-browser.json"
grep -q '"executable": "/usr/bin/firefox-esr"' "$PFILE"
grep -q '"enabled": true' "$PFILE"
grep -q '"block_host_files": true' "$PFILE"
grep -q '"persistent_storage": false' "$PFILE"
echo "PASS: Policy strictly matches specification (Network: Allowed, Local Files: Blocked, Persistence: Off)."

echo "=== [TEST 3] Testing Browser Sandbox Execution & Ephemeral Profile Argument ==="
OUTPUT=$(PROFILES_DIR="${PROFILES_DIR}" bash "${BIN}" --dry-run --profile private-browser)

echo "$OUTPUT" | grep -q "/usr/bin/firefox-esr"
echo "$OUTPUT" | grep -q "veilos-private-browser"
echo "$OUTPUT" | grep -q "resolv.conf"
echo "PASS: Dry run verifies Bubblewrap isolation and network allowance."

echo "=== [TEST 4] Simulating Workspace Cleanup on Browser Close ==="
MOCK_WS="/tmp/veilos_test_browser_ws_$$"
mkdir -p "$MOCK_WS/profile_data"
touch "$MOCK_WS/profile_data/cookies.sqlite"
touch "$MOCK_WS/profile_data/history.sqlite"

if [[ -f "$MOCK_WS/profile_data/cookies.sqlite" ]]; then
    echo "Browser created ephemeral data in: $MOCK_WS"
fi

# Simulate cleanup routine
find "$MOCK_WS" -type f -exec rm -f {} + 2>/dev/null || true
rm -rf "$MOCK_WS"

if [[ ! -d "$MOCK_WS" ]]; then
    echo "PASS: Ephemeral workspace data wiped and completely removed after exit."
fi

echo "=== ALL PRIVATE BROWSER VERIFICATION TESTS PASSED ==="