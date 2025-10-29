#!/bin/bash
# Local CI/CD test script for Android

set -e

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="${PROJECT_ROOT}/ci-reports"
APK_PATH="${REPORTS_DIR}/app-arm64-v8a-Release.apk"
DEVICE_SERIAL="${DEVICE_SERIAL:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "========================================"
log_info "Android CI/CD Test"
log_info "========================================"

# Step 1: Check APK exists
if [ ! -f "${APK_PATH}" ]; then
    log_error "APK not found: ${APK_PATH}"
    log_info "Please run build-android.sh first"
    exit 1
fi

log_success "APK found: ${APK_PATH}"

# Step 2: Check ADB connection
log_info "Step 2: Checking ADB connection..."

if [ -n "${DEVICE_SERIAL}" ]; then
    ADB_CMD="adb -s ${DEVICE_SERIAL}"
else
    ADB_CMD="adb"
fi

if ! ${ADB_CMD} devices | grep -q "device$"; then
    log_error "No Android device connected"
    log_info "Please connect a device or start an emulator"
    log_info "For WiFi debugging, run: ./connect_android_wifi.sh"
    exit 1
fi

DEVICE_INFO=$(${ADB_CMD} shell getprop ro.product.model)
log_success "Connected to: ${DEVICE_INFO}"

# Step 3: Uninstall previous version
log_info "Step 3: Uninstalling previous version..."

PACKAGE_NAME=$(aapt dump badging "${APK_PATH}" 2>/dev/null | grep "package:" | sed "s/.*name='\([^']*\)'.*/\1/")

if [ -n "${PACKAGE_NAME}" ]; then
    ${ADB_CMD} uninstall "${PACKAGE_NAME}" 2>/dev/null || true
    log_info "Package: ${PACKAGE_NAME}"
else
    log_warning "Could not determine package name"
fi

# Step 4: Install APK
log_info "Step 4: Installing APK..."

${ADB_CMD} install -r "${APK_PATH}" 2>&1 | tee "${REPORTS_DIR}/install.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_error "Installation failed"
    exit 1
fi

log_success "Installation completed"

# Step 5: Launch app
log_info "Step 5: Launching app..."

if [ -n "${PACKAGE_NAME}" ]; then
    # Clear logcat
    ${ADB_CMD} logcat -c
    
    # Launch app
    ${ADB_CMD} shell monkey -p "${PACKAGE_NAME}" -c android.intent.category.LAUNCHER 1
    
    log_info "Waiting for app to start..."
    sleep 5
    
    # Check if app is running
    if ${ADB_CMD} shell pidof "${PACKAGE_NAME}" > /dev/null 2>&1; then
        log_success "App is running"
    else
        log_warning "App may not be running"
    fi
fi

# Step 6: Collect logs
log_info "Step 6: Collecting logs..."

${ADB_CMD} logcat -d > "${REPORTS_DIR}/logcat.txt"
log_info "Logcat saved to: ${REPORTS_DIR}/logcat.txt"

# Filter for errors
grep -i "error\|exception\|crash" "${REPORTS_DIR}/logcat.txt" > "${REPORTS_DIR}/errors.txt" || true

if [ -s "${REPORTS_DIR}/errors.txt" ]; then
    log_warning "Errors found in logcat (see ${REPORTS_DIR}/errors.txt)"
    echo ""
    head -n 20 "${REPORTS_DIR}/errors.txt"
else
    log_success "No errors found in logcat"
fi

# Step 7: Capture screenshot
log_info "Step 7: Capturing screenshot..."

${ADB_CMD} exec-out screencap -p > "${REPORTS_DIR}/screenshot.png"
log_success "Screenshot saved to: ${REPORTS_DIR}/screenshot.png"

# Step 8: Performance metrics
log_info "Step 8: Collecting performance metrics..."

if [ -n "${PACKAGE_NAME}" ]; then
    ${ADB_CMD} shell dumpsys meminfo "${PACKAGE_NAME}" > "${REPORTS_DIR}/meminfo.txt"
    ${ADB_CMD} shell dumpsys cpuinfo > "${REPORTS_DIR}/cpuinfo.txt"
    
    log_info "Memory and CPU info collected"
fi

# Step 9: Generate test report
log_info "Step 9: Generating test report..."

cat > "${REPORTS_DIR}/test-report.txt" << EOF
========================================
Android CI/CD Test Report
========================================
Date: $(date)
Device: ${DEVICE_INFO}
Package: ${PACKAGE_NAME}
========================================

Test Status: COMPLETED

Installation: SUCCESS
App Launch: $(${ADB_CMD} shell pidof "${PACKAGE_NAME}" > /dev/null 2>&1 && echo "SUCCESS" || echo "FAILED")

Artifacts:
- Install Log: ${REPORTS_DIR}/install.log
- Logcat: ${REPORTS_DIR}/logcat.txt
- Errors: ${REPORTS_DIR}/errors.txt
- Screenshot: ${REPORTS_DIR}/screenshot.png
- Memory Info: ${REPORTS_DIR}/meminfo.txt
- CPU Info: ${REPORTS_DIR}/cpuinfo.txt

========================================
EOF

cat "${REPORTS_DIR}/test-report.txt"

log_success "========================================"
log_success "Test completed!"
log_success "========================================"
log_info "Reports: ${REPORTS_DIR}/"
log_success "========================================"

# Step 10: Interactive mode (optional)
if [ "${INTERACTIVE}" = "true" ]; then
    log_info "Entering interactive mode..."
    echo ""
    echo "Commands:"
    echo "  ${ADB_CMD} logcat -c              # Clear logcat"
    echo "  ${ADB_CMD} logcat                 # View live logs"
    echo "  ${ADB_CMD} shell pm clear ${PACKAGE_NAME}  # Clear app data"
    echo "  ${ADB_CMD} uninstall ${PACKAGE_NAME}       # Uninstall app"
    echo ""
fi

exit 0
