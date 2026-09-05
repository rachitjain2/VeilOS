#!/bin/bash
# ==============================================================================
# VEILOS Test Suite: PRIVACY CENTER & Security Transparency Checks
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin/veilos-privacy-center"

echo "=== [TEST 1] Verifying System Status Section in Privacy Center ==="
grep -q "SYSTEM STATUS" "$BIN"
grep -q "Session" "$BIN"
grep -q "TEMPORARY" "$BIN"
grep -q "Persistence" "$BIN"
grep -q "Application Sandboxing" "$BIN"
grep -q "Network Policy" "$BIN"
echo "PASS: All system status fields verified."

echo "=== [TEST 2] Verifying Applications Section in Privacy Center ==="
grep -q "APPLICATIONS" "$BIN"
grep -q "Private Browser" "$BIN"
grep -q "Developer Workspace" "$BIN"
grep -q "App Testing" "$BIN"
echo "PASS: All 3 core applications verified."

echo "=== [TEST 3] Verifying Security Enforcement Badges ==="
grep -q "✓ ENFORCED" "$BIN"
grep -q "◐ PARTIAL" "$BIN"
grep -q "○ NOT IMPLEMENTED" "$BIN"
echo "PASS: Explicit and honest security enforcement badges present."

echo "=== [TEST 4] Verifying 'Why?' Explanations ==="
grep -q "This application does not receive a configured path to your personal files." "$BIN"
echo "PASS: Non-technical 'Why?' policy explanations present and verified."

echo "=== ALL PRIVACY CENTER TESTS PASSED ==="