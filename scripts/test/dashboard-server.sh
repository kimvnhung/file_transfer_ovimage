#!/bin/bash

# Test Results Dashboard Server
# Serves a web interface to visualize test logs and build results

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DASHBOARD_DIR="$PROJECT_ROOT/ci-reports/dashboard"
PORT="${DASHBOARD_PORT:-8080}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[DASHBOARD]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[DASHBOARD]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[DASHBOARD]${NC} $1"
}

# Check if Python is available
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
        return 0
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
        return 0
    else
        log_warning "Python not found. Please install Python 3"
        return 1
    fi
}

# Generate dashboard HTML and assets
generate_dashboard() {
    log "Generating dashboard assets..."
    
    mkdir -p "$DASHBOARD_DIR"
    
    # Copy web files
    cp "$SCRIPT_DIR/../web/index.html" "$DASHBOARD_DIR/"
    cp "$SCRIPT_DIR/../web/dashboard.js" "$DASHBOARD_DIR/"
    cp "$SCRIPT_DIR/../web/styles.css" "$DASHBOARD_DIR/"
    
    # Generate test data JSON
    "$SCRIPT_DIR/generate-test-data.sh"
    
    log_success "Dashboard assets generated"
}

# Start HTTP server
start_server() {
    log "Starting test results dashboard..."
    log "Server URL: ${CYAN}http://localhost:$PORT${NC}"
    echo ""
    log "Press Ctrl+C to stop the server"
    echo ""
    
    cd "$PROJECT_ROOT/ci-reports"
    
    # Start Python HTTP server
    $PYTHON_CMD -m http.server $PORT
}

# Main
main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║          📊 TEST RESULTS DASHBOARD 📊                    ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    if ! check_python; then
        exit 1
    fi
    
    generate_dashboard
    
    log_success "Opening dashboard in browser..."
    
    # Try to open in browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:$PORT/dashboard/" &
    elif command -v open &> /dev/null; then
        open "http://localhost:$PORT/dashboard/" &
    fi
    
    sleep 1
    start_server
}

main
