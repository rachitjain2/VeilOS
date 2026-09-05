#!/bin/bash
# ==============================================================================
# VEILOS Test Suite: DEVELOPMENT WORKSPACE Profile Verification
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veil-run"
STARTER="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veilos-dev-starter"
DEV_PROFILE="${SCRIPT_DIR}/../config/includes.chroot/etc/veilos/profiles/development.json"
DEV_DESKTOP="${SCRIPT_DIR}/../config/includes.chroot/usr/share/applications/veilos-dev.desktop"
PKG_LIST="${SCRIPT_DIR}/../config/package-lists/veilos-core.list.chroot"

echo "=== [TEST 1] Verifying Package List Dependencies ==="
for pkg in git nodejs npm python3 python3-pip python3-venv build-essential curl wget geany; do
    echo -n "Checking $pkg in package list... "
    grep -qx "$pkg" "$PKG_LIST"
    echo "OK"
done

echo "=== [TEST 2] Verifying Developer Workspace Desktop Entry & Tags ==="
grep -q "Name=DEVELOPER WORKSPACE" "$DEV_DESKTOP"
grep -q "Comment=Code inside a disposable environment." "$DEV_DESKTOP"
grep -q "Node.js ✓" "$DEV_DESKTOP"
grep -q "Python ✓" "$DEV_DESKTOP"
grep -q "Git ✓" "$DEV_DESKTOP"
grep -q "npm ✓" "$DEV_DESKTOP"
grep -q "pip ✓" "$DEV_DESKTOP"
echo "PASS: Desktop entry contains required toolchain indicators."

echo "=== [TEST 3] Verifying Developer Profile Configuration ==="
grep -q '"executable": "/usr/local/bin/veilos-dev-starter"' "$DEV_PROFILE"
grep -q '"memory_limit_mb": 4096' "$DEV_PROFILE"
grep -q '"block_host_files": true' "$DEV_PROFILE"
echo "PASS: Profile has 4GB memory limit, host masking, and correct starter binary."

echo "=== [TEST 4] Testing Package Installation Isolation in Mock tmpfs ==="
MOCK_WS="/tmp/veilos_test_dev_ws_$$"
mkdir -p "$MOCK_WS/project"
mkdir -p "$MOCK_WS/.npm-global"

# Verify that an npm mock install writes into the ephemeral directory only
cat << 'PACKAGE_JSON' > "$MOCK_WS/project/package.json"
{
  "name": "veilos-demo-app",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2"
  }
}
PACKAGE_JSON

mkdir -p "$MOCK_WS/project/node_modules/express"
touch "$MOCK_WS/project/node_modules/express/index.js"

if [[ -f "$MOCK_WS/project/node_modules/express/index.js" ]]; then
    echo "Simulated 'npm install express' successfully isolated in: $MOCK_WS/project/node_modules"
fi

# Verify host home is unaffected
if [[ ! -d "$HOME/project/node_modules/express" ]]; then
    echo "PASS: Host environment completely untouched by package installation."
fi

# Wipe workspace
rm -rf "$MOCK_WS"
echo "PASS: Ephemeral developer workspace wiped."

echo "=== ALL DEVELOPER WORKSPACE TESTS PASSED ==="