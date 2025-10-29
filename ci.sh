#!/bin/bash
# Convenience wrapper for CI helper
# Redirects to scripts/build/ci-helper.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/scripts/build/ci-helper.sh" "$@"
