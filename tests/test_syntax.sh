#!/bin/bash
# ==============================================================================
# VEILOS Verification Test Suite: Sandbox & Scrubbing
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin"

echo "=== Running VEILOS Phase 1 Syntax & Integrity Checks ==="

for script in "${BIN_DIR}"/veilos-*; do
    if [[ -f "$script" ]]; then
        echo -n "Checking bash syntax: $(basename "$script")... "
        bash -n "$script"
        echo "OK"
    fi
done

echo "=== All script syntax checks passed ==="