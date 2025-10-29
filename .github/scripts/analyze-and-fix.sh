#!/bin/bash

# Self-Healing Build Script
# Analyzes build/cmake logs and attempts automatic fixes

set +e  # Don't exit on error, we want to try fixes

LOG_FILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIX_LOG="fix-log-$(date +%s).txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[ANALYZER]${NC} $1" | tee -a "$FIX_LOG"
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

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    log_error "Log file not found: $LOG_FILE"
    exit 1
fi

log "Analyzing build log: $LOG_FILE"
log "Project root: $PROJECT_ROOT"

cd "$PROJECT_ROOT" || exit 1

# Extract errors from log
extract_errors() {
    grep -i "error:\|Error:\|FAILED:\|CMake Error\|fatal error:" "$LOG_FILE" | head -20
}

# Pattern-based error detection and fixing
fix_missing_qml_imports() {
    log "Checking for missing QML import errors..."
    
    if grep -q "is not a type\|module.*is not installed" "$LOG_FILE"; then
        log_warning "Detected QML type errors"
        
        # Extract QML files with errors
        QML_FILES=$(grep -o "[^ ]*\.qml" "$LOG_FILE" | sort -u)
        
        for QML_FILE in $QML_FILES; do
            if [ -f "$PROJECT_ROOT/$QML_FILE" ]; then
                log "Analyzing $QML_FILE for missing imports..."
                
                # Check if using components without import
                if grep -q "CameraButton\|CameraListButton\|CameraPropertyButton" "$PROJECT_ROOT/$QML_FILE"; then
                    if ! grep -q 'import.*".*components"' "$PROJECT_ROOT/$QML_FILE"; then
                        log "Adding components import to $QML_FILE"
                        sed -i '1a import "../components"' "$PROJECT_ROOT/$QML_FILE"
                        log_success "Added components import"
                    fi
                fi
                
                # Check if using dialogs without import
                if grep -q "Popup\|CameraListPopup\|CameraPropertyPopup" "$PROJECT_ROOT/$QML_FILE"; then
                    if ! grep -q 'import.*".*dialogs"' "$PROJECT_ROOT/$QML_FILE"; then
                        log "Adding dialogs import to $QML_FILE"
                        sed -i '1a import "../dialogs"' "$PROJECT_ROOT/$QML_FILE"
                        log_success "Added dialogs import"
                    fi
                fi
                
                # Check if using controls without import
                if grep -q "PhotoCaptureControls\|VideoCaptureControls\|ZoomControl" "$PROJECT_ROOT/$QML_FILE"; then
                    if ! grep -q 'import.*".*controls"' "$PROJECT_ROOT/$QML_FILE"; then
                        log "Adding controls import to $QML_FILE"
                        sed -i '1a import "../controls"' "$PROJECT_ROOT/$QML_FILE"
                        log_success "Added controls import"
                    fi
                fi
            fi
        done
        
        return 0
    fi
    
    return 1
}

fix_missing_qml_element() {
    log "Checking for missing QML_ELEMENT macro..."
    
    if grep -q "module.*is not installed\|Type.*unavailable" "$LOG_FILE"; then
        log_warning "Detected missing QML type registration"
        
        # Find C++ header files that might need QML_ELEMENT
        CPP_HEADERS=$(find "$PROJECT_ROOT/include" "$PROJECT_ROOT/src" -name "*.h" 2>/dev/null)
        
        for HEADER in $CPP_HEADERS; do
            # Check if it's a Q_OBJECT class but missing QML_ELEMENT
            if grep -q "Q_OBJECT" "$HEADER" && ! grep -q "QML_ELEMENT" "$HEADER"; then
                # Check if it's likely a QML-exposed class (has Q_PROPERTY, Q_INVOKABLE, or signals)
                if grep -q "Q_PROPERTY\|Q_INVOKABLE\|signals:" "$HEADER"; then
                    log "Adding QML_ELEMENT to $HEADER"
                    
                    # Check if QQmlEngine is included
                    if ! grep -q "#include <QQmlEngine>" "$HEADER"; then
                        # Add include after first #include
                        sed -i '0,/#include/a #include <QQmlEngine>' "$HEADER"
                    fi
                    
                    # Add QML_ELEMENT after Q_OBJECT
                    sed -i '/Q_OBJECT/a \    QML_ELEMENT' "$HEADER"
                    
                    log_success "Added QML_ELEMENT to $HEADER"
                fi
            fi
        done
        
        return 0
    fi
    
    return 1
}

fix_opencv_not_found() {
    log "Checking for OpenCV not found errors..."
    
    if grep -qi "Could not find OpenCV\|OpenCV not found" "$LOG_FILE"; then
        log_warning "OpenCV not found, checking installation..."
        
        OPENCV_SDK="$HOME/Android/OpenCV-android-sdk"
        
        if [ ! -d "$OPENCV_SDK" ]; then
            log "Downloading OpenCV Android SDK..."
            mkdir -p "$HOME/Android"
            cd "$HOME/Android"
            
            OPENCV_VERSION="${OPENCV_VERSION:-4.10.0}"
            wget -q "https://github.com/opencv/opencv/releases/download/$OPENCV_VERSION/opencv-$OPENCV_VERSION-android-sdk.zip" -O opencv.zip
            
            if [ $? -eq 0 ]; then
                unzip -q opencv.zip
                mv OpenCV-android-sdk OpenCV-android-sdk 2>/dev/null || true
                rm opencv.zip
                log_success "OpenCV Android SDK downloaded"
                cd "$PROJECT_ROOT"
                return 0
            else
                log_error "Failed to download OpenCV"
                cd "$PROJECT_ROOT"
                return 1
            fi
        else
            log "OpenCV SDK exists at $OPENCV_SDK"
        fi
    fi
    
    return 1
}

fix_missing_dependencies() {
    log "Checking for missing dependency errors..."
    
    if grep -qi "Could not find.*Qt6\|Qt6.*not found" "$LOG_FILE"; then
        log_error "Qt6 not found - this requires manual intervention"
        log "Please install Qt 6.10.0 for Android"
        return 1
    fi
    
    if grep -qi "Could not find.*NDK\|NDK.*not found" "$LOG_FILE"; then
        log_warning "Android NDK not found"
        
        if [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
            log "Installing NDK via sdkmanager..."
            "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" "ndk;27.2.12479018"
            
            if [ $? -eq 0 ]; then
                log_success "NDK installed"
                return 0
            fi
        fi
        
        log_error "Failed to install NDK"
        return 1
    fi
    
    return 1
}

fix_cmake_syntax_errors() {
    log "Checking for CMake syntax errors..."
    
    if grep -qi "CMake Error.*syntax error" "$LOG_FILE"; then
        log_error "CMake syntax error detected - requires manual review"
        
        # Extract the problematic line
        ERROR_LINE=$(grep -A 2 "CMake Error.*syntax error" "$LOG_FILE" | head -5)
        log "$ERROR_LINE"
        
        return 1
    fi
    
    return 1
}

fix_compiler_errors() {
    log "Checking for C++ compiler errors..."
    
    if grep -qi "error:.*undeclared identifier\|error:.*no member named" "$LOG_FILE"; then
        log_warning "Detected missing includes or forward declarations"
        
        # Extract files with errors
        ERROR_FILES=$(grep -o "[^ ]*\.cpp:[0-9]*:[0-9]*: error:" "$LOG_FILE" | cut -d: -f1 | sort -u)
        
        for CPP_FILE in $ERROR_FILES; do
            if [ -f "$PROJECT_ROOT/$CPP_FILE" ]; then
                log "Analyzing $CPP_FILE..."
                
                # Common missing includes
                if grep -q "QQmlEngine\|qmlRegisterType" "$CPP_FILE"; then
                    if ! grep -q "#include <QQmlEngine>" "$CPP_FILE"; then
                        log "Adding missing QQmlEngine include"
                        sed -i '1a #include <QQmlEngine>' "$CPP_FILE"
                        log_success "Added QQmlEngine include to $CPP_FILE"
                    fi
                fi
                
                if grep -q "QQuickItem\|QQuickPaintedItem" "$CPP_FILE"; then
                    if ! grep -q "#include <QQuickItem>" "$CPP_FILE" && ! grep -q "#include <QQuickPaintedItem>" "$CPP_FILE"; then
                        log "Adding missing QQuick include"
                        sed -i '1a #include <QQuickPaintedItem>' "$CPP_FILE"
                        log_success "Added QQuick include to $CPP_FILE"
                    fi
                fi
            fi
        done
        
        return 0
    fi
    
    return 1
}

fix_permission_issues() {
    log "Checking for permission errors..."
    
    if grep -qi "Permission denied" "$LOG_FILE"; then
        log_warning "Permission errors detected"
        
        # Make scripts executable
        find "$PROJECT_ROOT" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null
        
        log_success "Updated script permissions"
        return 0
    fi
    
    return 1
}

# Main analysis and fix routine
main() {
    log "Starting error analysis and auto-fix..."
    log "========================================"
    
    # Show detected errors
    log "Detected errors:"
    extract_errors | tee -a "$FIX_LOG"
    log "========================================"
    
    FIXED=false
    
    # Try each fix strategy
    if fix_missing_qml_imports; then
        log_success "Applied QML import fixes"
        FIXED=true
    fi
    
    if fix_missing_qml_element; then
        log_success "Applied QML element registration fixes"
        FIXED=true
    fi
    
    if fix_opencv_not_found; then
        log_success "Applied OpenCV fixes"
        FIXED=true
    fi
    
    if fix_missing_dependencies; then
        log_success "Applied dependency fixes"
        FIXED=true
    fi
    
    if fix_cmake_syntax_errors; then
        log_warning "CMake syntax errors require manual intervention"
    fi
    
    if fix_compiler_errors; then
        log_success "Applied compiler error fixes"
        FIXED=true
    fi
    
    if fix_permission_issues; then
        log_success "Fixed permission issues"
        FIXED=true
    fi
    
    log "========================================"
    
    if [ "$FIXED" = true ]; then
        log_success "Auto-fixes applied! Retrying build..."
        
        # Commit fixes if in CI environment
        if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
            git config --global user.name "GitHub Actions Bot"
            git config --global user.email "actions@github.com"
            
            git add -A
            
            if git diff --cached --quiet; then
                log "No changes to commit"
            else
                git commit -m "fix: auto-fix build errors [skip ci]" || true
                log_success "Committed auto-fixes"
            fi
        fi
        
        return 0
    else
        log_warning "No automatic fixes could be applied"
        log "Manual intervention may be required"
        return 1
    fi
}

# Run main routine
main
EXIT_CODE=$?

log "========================================"
log "Fix log saved to: $FIX_LOG"

exit $EXIT_CODE
