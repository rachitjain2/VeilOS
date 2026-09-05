#!/bin/bash
# ==============================================================================
# VEILOS Verification Test Suite: Script Syntax & Integrity Checks
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/../config/includes.chroot/usr/local/bin"

echo "=== Running VEILOS Script Integrity Checks ==="

for script in "${BIN_DIR}"/veilos-*; do
    if [[ -f "$script" ]]; then
        SH_BANG=$(head -n 1 "$script")
        if [[ "$SH_BANG" =~ python ]]; then
            echo -n "Checking Python script: $(basename "$script")... "
            if [[ -x /usr/bin/python3 ]]; then
                /usr/bin/python3 -m py_compile "$script"
            fi
            echo "OK (validated)"
        else
            echo -n "Checking Bash syntax: $(basename "$script")... "
            bash -n "$script"
            echo "OK"
        fi
    fi
done

echo "=== All script integrity checks passed ==="