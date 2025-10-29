#!/bin/bash
# Convenience wrapper for runtime testing
# Redirects to scripts/test/test-runtime-self-healing.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/scripts/test/test-runtime-self-healing.sh" "$@"
