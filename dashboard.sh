#!/bin/bash
# Dashboard wrapper script
exec "$(dirname "$0")/scripts/test/dashboard-server.sh" "$@"
