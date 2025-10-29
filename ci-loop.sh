#!/bin/bash

# CI Loop - Convenient wrapper for build-test-loop.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
ITERATIONS=1

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--iterations)
            ITERATIONS="$2"
            shift 2
            ;;
        -h|--help)
            cat << EOF
CI Loop - Continuous Build, Test, and Report

Usage: $0 [OPTIONS]

Options:
  -n, --iterations NUM    Number of iterations to run (default: 1)
  -h, --help             Show this help message

Examples:
  $0                     # Run once
  $0 -n 3                # Run 3 iterations
  $0 --iterations 5      # Run 5 iterations

What it does:
  1. Build APK using cmake
  2. Install APK to connected device
  3. Run runtime self-healing tests
  4. Generate report and dashboard data

Results are saved to ci-reports/ directory.
View dashboard: ./dashboard.sh

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Set environment variable and run
export MAX_ITERATIONS=$ITERATIONS

exec "$SCRIPT_DIR/build-test-loop.sh"
