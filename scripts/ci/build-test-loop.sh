#!/bin/bash

# Continuous Build-Test Loop
# Automatically builds, installs, tests, and reports results

set +e  # Don't exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[LOOP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_stage() {
    echo ""
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  $1${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Configuration
MAX_ITERATIONS="${MAX_ITERATIONS:-1}"
REPORT_DIR="$PROJECT_ROOT/ci-reports"
DASHBOARD_DIR="$REPORT_DIR/dashboard"
LOOP_LOG="$REPORT_DIR/build-test-loop-$(date +%s).log"

mkdir -p "$REPORT_DIR"
mkdir -p "$DASHBOARD_DIR"

# Statistics
TOTAL_BUILDS=0
SUCCESSFUL_BUILDS=0
FAILED_BUILDS=0
TOTAL_TESTS=0
SUCCESSFUL_TESTS=0
FAILED_TESTS=0

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}║     🔄 CONTINUOUS BUILD-TEST-REPORT LOOP 🔄              ║${NC}"
echo -e "${CYAN}║                                                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

log "Starting continuous integration loop"
log "Max iterations: $MAX_ITERATIONS"
log "Report directory: $REPORT_DIR"
log "Loop log: $LOOP_LOG"
echo ""

# Function to build
do_build() {
    local iteration=$1
    
    log_stage "STAGE 1: BUILD (#$iteration)"
    
    log "Building APK..."
    
    if "$PROJECT_ROOT/scripts/build/cmake-build.sh" 2>&1 | tee -a "$LOOP_LOG"; then
        log_success "Build successful"
        SUCCESSFUL_BUILDS=$((SUCCESSFUL_BUILDS + 1))
        return 0
    else
        log_error "Build failed"
        FAILED_BUILDS=$((FAILED_BUILDS + 1))
        return 1
    fi
}

# Function to install
do_install() {
    log_stage "STAGE 2: INSTALL"
    
    log "Checking for device..."
    
    if ! command -v adb &> /dev/null; then
        log_error "ADB not found"
        return 1
    fi
    
    DEVICE=$(adb devices | grep -w "device" | head -1 | awk '{print $1}')
    
    if [ -z "$DEVICE" ]; then
        log_error "No device connected"
        echo ""
        echo "Please connect a device via:"
        echo "  1. USB cable, or"
        echo "  2. WiFi: ./scripts/setup/connect_android_wifi.sh"
        return 1
    fi
    
    log_success "Device connected: $DEVICE"
    
    # Find APK
    APK="$PROJECT_ROOT/app-debug.apk"
    if [ ! -f "$APK" ]; then
        log_error "APK not found at: $APK"
        return 1
    fi
    
    log "Installing APK..."
    
    if adb install -r "$APK" 2>&1 | tee -a "$LOOP_LOG"; then
        log_success "APK installed successfully"
        return 0
    else
        log_error "Installation failed"
        return 1
    fi
}

# Function to test
do_test() {
    log_stage "STAGE 3: RUNTIME TEST"
    
    log "Running self-healing runtime test..."
    
    if "$PROJECT_ROOT/test.sh" 2>&1 | tee -a "$LOOP_LOG"; then
        log_success "Runtime test passed"
        SUCCESSFUL_TESTS=$((SUCCESSFUL_TESTS + 1))
        return 0
    else
        log_warning "Runtime test detected errors"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to generate report
do_report() {
    log_stage "STAGE 4: GENERATE REPORT"
    
    log "Generating test data..."
    
    if "$PROJECT_ROOT/scripts/test/generate-test-data.sh" 2>&1 | tee -a "$LOOP_LOG"; then
        log_success "Test data generated"
    else
        log_warning "Test data generation had issues"
    fi
    
    # Create summary report
    local summary_file="$REPORT_DIR/loop-summary-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$summary_file" << EOF
═══════════════════════════════════════════════════════════
BUILD-TEST LOOP SUMMARY
═══════════════════════════════════════════════════════════

Date: $(date '+%Y-%m-%d %H:%M:%S')
Project: file_transfer_ovimage

═══════════════════════════════════════════════════════════
STATISTICS
═══════════════════════════════════════════════════════════

Iterations: $TOTAL_BUILDS

Builds:
  Total:      $TOTAL_BUILDS
  Successful: $SUCCESSFUL_BUILDS
  Failed:     $FAILED_BUILDS
  Success %:  $([ $TOTAL_BUILDS -gt 0 ] && echo $((SUCCESSFUL_BUILDS * 100 / TOTAL_BUILDS)) || echo 0)%

Tests:
  Total:      $TOTAL_TESTS
  Passed:     $SUCCESSFUL_TESTS
  Failed:     $FAILED_TESTS
  Success %:  $([ $TOTAL_TESTS -gt 0 ] && echo $((SUCCESSFUL_TESTS * 100 / TOTAL_TESTS)) || echo 0)%

═══════════════════════════════════════════════════════════
ARTIFACTS
═══════════════════════════════════════════════════════════

APK:           $PROJECT_ROOT/app-debug.apk
Loop Log:      $LOOP_LOG
Test Reports:  $REPORT_DIR/runtime-test/
Dashboard:     $DASHBOARD_DIR/
Summary:       $summary_file

═══════════════════════════════════════════════════════════
VIEW RESULTS
═══════════════════════════════════════════════════════════

To view dashboard:
  ./dashboard.sh

To view this summary:
  cat $summary_file

EOF
    
    log_success "Summary report created: $summary_file"
    
    # Display summary
    cat "$summary_file"
    
    return 0
}

# Main loop
main() {
    local start_time=$(date +%s)
    
    for iteration in $(seq 1 $MAX_ITERATIONS); do
        echo ""
        echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                 ITERATION $iteration of $MAX_ITERATIONS${NC}"
        echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        
        TOTAL_BUILDS=$((TOTAL_BUILDS + 1))
        
        # Stage 1: Build
        if ! do_build "$iteration"; then
            log_error "Build failed, stopping loop"
            break
        fi
        
        # Stage 2: Install
        if ! do_install; then
            log_error "Installation failed, stopping loop"
            break
        fi
        
        # Stage 3: Test
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        do_test  # Don't stop on test failure, just record it
        
        # Brief pause between iterations
        if [ $iteration -lt $MAX_ITERATIONS ]; then
            log "Waiting 3 seconds before next iteration..."
            sleep 3
        fi
    done
    
    # Stage 4: Report
    do_report
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    log_stage "LOOP COMPLETE"
    
    log "Total duration: ${duration}s"
    log "Total iterations: $TOTAL_BUILDS"
    log "Build success rate: $SUCCESSFUL_BUILDS/$TOTAL_BUILDS"
    log "Test success rate: $SUCCESSFUL_TESTS/$TOTAL_TESTS"
    
    echo ""
    
    if [ $FAILED_BUILDS -eq 0 ] && [ $FAILED_TESTS -eq 0 ]; then
        log_success "✅ All iterations completed successfully!"
    elif [ $FAILED_BUILDS -gt 0 ]; then
        log_error "❌ Some builds failed"
    else
        log_warning "⚠️  Some tests failed"
    fi
    
    echo ""
    log "View dashboard: ./dashboard.sh"
    echo ""
}

# Handle Ctrl+C
trap 'echo ""; log_warning "Loop interrupted by user"; do_report; exit 130' INT

# Run main loop
main

# Exit with appropriate code
if [ $FAILED_BUILDS -gt 0 ]; then
    exit 1
elif [ $FAILED_TESTS -gt 0 ]; then
    exit 2
else
    exit 0
fi
