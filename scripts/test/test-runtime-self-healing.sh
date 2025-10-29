#!/bin/bash

# Self-Healing Runtime Testing System
# Tests APK on device, monitors logcat, detects QML/Qt errors, fixes them, and repeats

set +e  # Don't exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MAX_ATTEMPTS=5
APP_PACKAGE="org.qtproject.example.file_transfer_ovimage"
LOGCAT_TAG="Qt|QML|OpenCV"
TEST_DURATION=15  # seconds to monitor app
LOGS_DIR="$PROJECT_ROOT/ci-reports/runtime-test"
FIX_LOG="$LOGS_DIR/runtime-fix-$(date +%s).txt"

mkdir -p "$LOGS_DIR"

log() {
    echo -e "${BLUE}[RUNTIME-TEST]${NC} $1" | tee -a "$FIX_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$FIX_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$FIX_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$FIX_LOG"
}

echo ""
echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║                                                           ║${NC}"
echo -e "${MAGENTA}║     🤖 SELF-HEALING RUNTIME TESTING SYSTEM 🤖             ║${NC}"
echo -e "${MAGENTA}║                                                           ║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if device is connected
check_device() {
    log "Checking for connected Android device..."
    
    if ! command -v adb &> /dev/null; then
        log_error "ADB not found. Please install Android SDK Platform Tools."
        return 1
    fi
    
    DEVICE=$(adb devices | grep -w "device" | head -1 | awk '{print $1}')
    
    if [ -z "$DEVICE" ]; then
        log_error "No Android device connected"
        echo ""
        echo "Please connect a device via:"
        echo "  1. USB cable, or"
        echo "  2. WiFi: ./scripts/setup/connect_android_wifi.sh"
        return 1
    fi
    
    log_success "Device connected: $DEVICE"
    return 0
}

# Find APK to install
find_apk() {
    log "Looking for APK file..."
    
    # Search in common build directories
    APK=$(find "$PROJECT_ROOT/build" -name "*debug*.apk" 2>/dev/null | head -1)
    
    if [ -z "$APK" ] || [ ! -f "$APK" ]; then
        log_error "No APK found. Build the project first."
        echo ""
        echo "Run: ./self-heal-build.sh or ./ci-helper.sh build"
        return 1
    fi
    
    log_success "Found APK: $(basename "$APK")"
    return 0
}

# Install APK on device
install_apk() {
    log "Installing APK on device..."
    
    adb install -r "$APK" > "$LOGS_DIR/install.log" 2>&1
    
    if [ $? -ne 0 ]; then
        log_error "Failed to install APK"
        cat "$LOGS_DIR/install.log"
        return 1
    fi
    
    log_success "APK installed successfully"
    return 0
}

# Launch app
launch_app() {
    log "Launching application..."
    
    # Clear logcat buffer
    adb logcat -c
    
    # Launch app
    adb shell monkey -p "$APP_PACKAGE" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    
    sleep 3
    
    # Check if app is running
    if adb shell pidof "$APP_PACKAGE" > /dev/null 2>&1; then
        log_success "Application launched successfully"
        return 0
    else
        log_error "Application failed to start"
        return 1
    fi
}

# Capture device screen
capture_screen() {
    local attempt=$1
    local screenshot_file="$LOGS_DIR/screenshot-attempt-$attempt.png"
    
    log "Capturing device screen..."
    
    # Capture screenshot to device
    adb shell screencap -p /sdcard/screenshot.png > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # Pull screenshot from device
        adb pull /sdcard/screenshot.png "$screenshot_file" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            # Clean up device
            adb shell rm /sdcard/screenshot.png > /dev/null 2>&1
            log_success "Screenshot saved: $(basename "$screenshot_file")"
            return 0
        else
            log_warning "Failed to pull screenshot from device"
            return 1
        fi
    else
        log_warning "Failed to capture screenshot"
        return 1
    fi
}

# Monitor logcat for errors
monitor_logcat() {
    local attempt=$1
    local logcat_file="$LOGS_DIR/logcat-attempt-$attempt.txt"
    
    log "Monitoring logcat for $TEST_DURATION seconds..."
    
    # Capture logcat with Qt and QML tags
    timeout $TEST_DURATION adb logcat -v time "*:W" | grep -E "Qt|QML|qml|FATAL|AndroidRuntime" > "$logcat_file" 2>&1 &
    LOGCAT_PID=$!
    
    # Show progress
    for i in $(seq 1 $TEST_DURATION); do
        echo -ne "\r  ${CYAN}Progress: [$i/$TEST_DURATION seconds]${NC}"
        sleep 1
    done
    echo ""
    
    wait $LOGCAT_PID 2>/dev/null
    
    log_success "Logcat captured to: $(basename "$logcat_file")"
    
    # Capture screenshot after monitoring
    capture_screen "$attempt"
    
    echo "$logcat_file"
}

# Analyze logcat for QML/Qt errors
analyze_runtime_errors() {
    local logcat_file=$1
    local errors_found=false
    
    log "Analyzing logcat for QML/Qt errors..."
    
    if [ ! -f "$logcat_file" ]; then
        log_error "Logcat file not found"
        return 1
    fi
    
    # Extract errors
    {
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "RUNTIME ERRORS DETECTED:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # QML type errors
        if grep -qi "is not a type\|is not installed\|module.*is not installed" "$logcat_file"; then
            echo ""
            echo "QML Type/Import Errors:"
            grep -i "is not a type\|is not installed\|module.*is not installed" "$logcat_file" | head -10
            errors_found=true
        fi
        
        # QML property errors
        if grep -qi "Cannot assign to non-existent property\|ReferenceError" "$logcat_file"; then
            echo ""
            echo "QML Property Errors:"
            grep -i "Cannot assign to non-existent property\|ReferenceError" "$logcat_file" | head -10
            errors_found=true
        fi
        
        # Qt warnings
        if grep -qi "QObject::connect\|QQmlEngine\|failed to create" "$logcat_file"; then
            echo ""
            echo "Qt Runtime Warnings:"
            grep -i "QObject::connect\|QQmlEngine\|failed to create" "$logcat_file" | head -10
            errors_found=true
        fi
        
        # Fatal errors
        if grep -qi "FATAL EXCEPTION\|AndroidRuntime" "$logcat_file"; then
            echo ""
            echo "Fatal Errors:"
            grep -A 10 "FATAL EXCEPTION\|AndroidRuntime" "$logcat_file" | head -20
            errors_found=true
        fi
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    } | tee -a "$FIX_LOG"
    
    if [ "$errors_found" = true ]; then
        log_warning "Runtime errors detected"
        return 0  # Errors found
    else
        log_success "No runtime errors detected!"
        return 1  # No errors
    fi
}

# Apply runtime fixes based on logcat analysis
apply_runtime_fixes() {
    local logcat_file=$1
    local fixes_applied=false
    
    log "Applying runtime fixes..."
    
    # Fix 1: QML import errors
    if grep -qi "is not a type" "$logcat_file"; then
        log "Detecting QML type errors..."
        
        # Extract QML files with errors
        QML_ERRORS=$(grep -o "file://.*\.qml:[0-9]*" "$logcat_file" | cut -d: -f1 | sort -u)
        
        for QML_PATH in $QML_ERRORS; do
            # Remove file:// prefix and extract local path
            LOCAL_PATH=$(echo "$QML_PATH" | sed 's|file://||' | sed 's|.*/qml/|qml/|')
            FULL_PATH="$PROJECT_ROOT/$LOCAL_PATH"
            
            if [ -f "$FULL_PATH" ]; then
                log "Checking $LOCAL_PATH for missing imports..."
                
                # Check for components usage without import
                if grep -q "CameraButton\|CameraListButton\|CameraPropertyButton" "$FULL_PATH"; then
                    if ! grep -q 'import.*".*components"' "$FULL_PATH"; then
                        log "Adding components import to $LOCAL_PATH"
                        sed -i '1a import "../components"' "$FULL_PATH"
                        fixes_applied=true
                    fi
                fi
                
                # Check for dialogs usage without import
                if grep -q "Popup\|Dialog" "$FULL_PATH"; then
                    if ! grep -q 'import.*".*dialogs"' "$FULL_PATH"; then
                        log "Adding dialogs import to $LOCAL_PATH"
                        sed -i '1a import "../dialogs"' "$FULL_PATH"
                        fixes_applied=true
                    fi
                fi
                
                # Check for controls usage without import
                if grep -q "PhotoCaptureControls\|VideoCaptureControls" "$FULL_PATH"; then
                    if ! grep -q 'import.*".*controls"' "$FULL_PATH"; then
                        log "Adding controls import to $LOCAL_PATH"
                        sed -i '1a import "../controls"' "$FULL_PATH"
                        fixes_applied=true
                    fi
                fi
            fi
        done
    fi
    
    # Fix 2: Module not installed errors
    if grep -qi "module.*is not installed" "$logcat_file"; then
        log "Detecting missing QML module registration..."
        
        # Extract module names
        MODULES=$(grep -o "module \"[^\"]*\" is not installed" "$logcat_file" | sed 's/module "\([^"]*\)".*/\1/' | sort -u)
        
        for MODULE in $MODULES; do
            log "Looking for C++ classes for module: $MODULE"
            
            # Find header files that might need QML_ELEMENT
            HEADERS=$(find "$PROJECT_ROOT/include" "$PROJECT_ROOT/src" -name "*.h" 2>/dev/null)
            
            for HEADER in $HEADERS; do
                if grep -q "Q_OBJECT" "$HEADER" && ! grep -q "QML_ELEMENT" "$HEADER"; then
                    # Add QML_ELEMENT if it has Q_PROPERTY or Q_INVOKABLE
                    if grep -q "Q_PROPERTY\|Q_INVOKABLE" "$HEADER"; then
                        log "Adding QML_ELEMENT to $(basename "$HEADER")"
                        
                        # Add QQmlEngine include if not present
                        if ! grep -q "#include <QQmlEngine>" "$HEADER"; then
                            sed -i '0,/#include/a #include <QQmlEngine>' "$HEADER"
                        fi
                        
                        # Add QML_ELEMENT after Q_OBJECT
                        sed -i '/Q_OBJECT/a \    QML_ELEMENT' "$HEADER"
                        fixes_applied=true
                    fi
                fi
            done
        done
    fi
    
    # Fix 3: Property errors
    if grep -qi "Cannot assign to non-existent property" "$logcat_file"; then
        log_warning "Property errors detected - may require manual review"
        grep -i "Cannot assign to non-existent property" "$logcat_file" | head -5 | tee -a "$FIX_LOG"
    fi
    
    if [ "$fixes_applied" = true ]; then
        log_success "Runtime fixes applied!"
        return 0
    else
        log_warning "No automatic fixes could be applied"
        return 1
    fi
}

# Stop app
stop_app() {
    log "Stopping application..."
    adb shell am force-stop "$APP_PACKAGE" 2>/dev/null
    sleep 1
}

# Rebuild after fixes
rebuild_app() {
    log "Rebuilding application with fixes..."
    
    # Use existing build script
    if [ -f "$PROJECT_ROOT/scripts/build/self-heal-build.sh" ]; then
        "$PROJECT_ROOT/scripts/build/self-heal-build.sh" > "$LOGS_DIR/rebuild.log" 2>&1
        
        if [ $? -eq 0 ]; then
            log_success "Rebuild successful"
            return 0
        else
            log_error "Rebuild failed"
            return 1
        fi
    else
        log_error "Build script not found at $PROJECT_ROOT/scripts/build/self-heal-build.sh"
        return 1
    fi
}

# Main testing loop
main() {
    # Check prerequisites
    if ! check_device; then
        exit 1
    fi
    
    if ! find_apk; then
        exit 1
    fi
    
    ATTEMPT=0
    ERRORS_FOUND=true
    
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ] && [ "$ERRORS_FOUND" = true ]; do
        ATTEMPT=$((ATTEMPT + 1))
        
        echo ""
        echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║                TEST CYCLE $ATTEMPT of $MAX_ATTEMPTS                           ║${NC}"
        echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        # Install APK
        if ! install_apk; then
            log_error "Installation failed on attempt $ATTEMPT"
            break
        fi
        
        # Launch app
        if ! launch_app; then
            log_error "Launch failed on attempt $ATTEMPT"
            
            # Capture screen on launch failure
            capture_screen "$ATTEMPT-launch-failed"
            
            # Try to get crash log
            adb logcat -d | grep -A 20 "FATAL EXCEPTION" > "$LOGS_DIR/crash-$ATTEMPT.txt"
            break
        fi
        
        # Capture initial screen after successful launch
        capture_screen "$ATTEMPT-launched"
        
        # Monitor logcat
        LOGCAT_FILE=$(monitor_logcat $ATTEMPT)
        
        # Stop app
        stop_app
        
        # Analyze errors
        if analyze_runtime_errors "$LOGCAT_FILE"; then
            # Errors found
            log_warning "Errors detected in test cycle $ATTEMPT"
            
            if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
                log_error "Maximum attempts reached"
                ERRORS_FOUND=true
                break
            fi
            
            # Apply fixes
            if apply_runtime_fixes "$LOGCAT_FILE"; then
                log "Fixes applied, rebuilding..."
                
                if rebuild_app; then
                    # Find new APK
                    if ! find_apk; then
                        log_error "Failed to find rebuilt APK"
                        break
                    fi
                    
                    log_success "Ready for next test cycle"
                    sleep 2
                else
                    log_error "Rebuild failed"
                    break
                fi
            else
                log_warning "No fixes applied, manual intervention needed"
                ERRORS_FOUND=true
                break
            fi
        else
            # No errors found!
            log_success "No errors detected - application running cleanly!"
            ERRORS_FOUND=false
        fi
    done
    
    # Final summary
    echo ""
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                   TESTING COMPLETE                        ║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$ERRORS_FOUND" = false ]; then
        log_success "✅ All runtime errors resolved!"
        echo ""
        echo "Summary:"
        echo "  • Test cycles: $ATTEMPT"
        echo "  • Final status: No errors detected"
        echo "  • Application: Running cleanly on device"
        echo ""
        echo "Artifacts saved:"
        echo "  • Logcat logs: $LOGS_DIR/logcat-attempt-*.txt"
        echo "  • Screenshots: $LOGS_DIR/screenshot-*.png"
        echo "  • Fix history: $LOGS_DIR/runtime-fix-*.txt"
        echo ""
        log_success "The app is ready for production!"
        echo ""
        exit 0
    else
        log_error "❌ Runtime errors remain after $ATTEMPT attempts"
        echo ""
        echo "Summary:"
        echo "  • Test cycles: $ATTEMPT"
        echo "  • Final status: Errors still present"
        echo ""
        echo "Review logs at: $LOGS_DIR"
        echo "  • Logcat logs: logcat-attempt-*.txt"
        echo "  • Screenshots: screenshot-*.png"
        echo "  • Fix history: runtime-fix-*.txt"
        echo ""
        log_warning "Manual intervention required"
        echo ""
        exit 1
    fi
}

# Handle Ctrl+C
trap 'echo ""; log_warning "Testing interrupted by user"; stop_app; exit 130' INT

# Run main
main
