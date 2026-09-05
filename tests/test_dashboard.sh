#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veilos-dashboard"

echo -n "Checking script structure for veilos-dashboard... "
grep -q "class VeilosDashboard" "$BIN"
grep -q "def build_status_panel" "$BIN"
grep -q "PRIVATE BROWSER" "$BIN"
grep -q "DEVELOPER WORKSPACE" "$BIN"
grep -q "APP SANDBOX" "$BIN"
grep -q "SECURE VAULT" "$BIN"
grep -q "PRIVACY CENTER" "$BIN"
grep -q "END SESSION" "$BIN"
echo "OK (All Phase 2 components verified)"