#!/bin/bash

# Full Process Test Runner
# Runs comprehensive end-to-end tests for the steganography system
#
# Usage: ./run_full_process_test.sh

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build/Desktop_Tests"
TEST_EXECUTABLE="${BUILD_DIR}/tests/test_full_process_e2e"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Full Process End-to-End Test Runner${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if build directory exists
if [ ! -d "${BUILD_DIR}" ]; then
    echo -e "${YELLOW}Build directory not found. Building tests...${NC}"
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"
    cmake ../.. -GNinja -DBUILD_TESTS=ON \
        -DCMAKE_BUILD_TYPE=Debug \
        -DQT_QMAKE_EXECUTABLE=/home/hungkv/Qt/6.10.0/gcc_64/bin/qmake6 \
        -DCMAKE_PREFIX_PATH=/home/hungkv/Qt/6.10.0/gcc_64
    ninja test_full_process_e2e
fi

# Check if executable exists
if [ ! -f "${TEST_EXECUTABLE}" ]; then
    echo -e "${YELLOW}Test executable not found. Building...${NC}"
    cd "${BUILD_DIR}"
    ninja test_full_process_e2e
fi

echo -e "${GREEN}Running full process tests...${NC}"
echo ""

# Run the test
cd "${BUILD_DIR}"
"${TEST_EXECUTABLE}" "$@"

exit_code=$?

echo ""
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  All tests passed!${NC}"
    echo -e "${GREEN}============================================${NC}"
else
    echo -e "${YELLOW}============================================${NC}"
    echo -e "${YELLOW}  Some tests failed (exit code: $exit_code)${NC}"
    echo -e "${YELLOW}============================================${NC}"
fi

exit $exit_code
