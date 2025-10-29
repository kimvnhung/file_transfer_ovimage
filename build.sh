#!/bin/bash
# Convenience wrapper for self-healing build
# Redirects to scripts/build/self-heal-build.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/scripts/build/self-heal-build.sh" "$@"
