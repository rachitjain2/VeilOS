#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Scrubbing live-build temporary states..."
cd "${ROOT_DIR}"
if command -v lb >/dev/null 2>&1; then
    lb clean --purge || true
fi
rm -rf .build chroot binary cache output/*.log
echo "Clean complete."