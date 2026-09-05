#!/bin/bash
# ==============================================================================
# VEILOS Main Root Build Pipeline
# Invokes build/build.sh from repository root
# ==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/build/build.sh" "$@"