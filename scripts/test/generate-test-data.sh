#!/bin/bash

# Generate test data JSON from logs
# Aggregates test results for dashboard visualization

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CI_REPORTS="$PROJECT_ROOT/ci-reports"
OUTPUT_JSON="$CI_REPORTS/dashboard/test-data.json"

mkdir -p "$CI_REPORTS/dashboard"

# Parse runtime test logs
parse_runtime_tests() {
    local test_dir="$CI_REPORTS/runtime-test"
    local builds=()
    
    if [ ! -d "$test_dir" ]; then
        echo "[]"
        return
    fi
    
    # Find all logcat files
    local logcat_files=$(find "$test_dir" -name "logcat-attempt-*.txt" 2>/dev/null | sort -r)
    
    local build_id=1
    local current_build=""
    
    for logcat in $logcat_files; do
        local attempt=$(basename "$logcat" | grep -oP 'attempt-\K\d+')
        local timestamp=$(stat -c %Y "$logcat" 2>/dev/null || echo "0")
        local date=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
        
        # Count errors
        local qml_errors=$(grep -ci "qml\|is not a type" "$logcat" 2>/dev/null || echo "0")
        local qt_errors=$(grep -ci "qobject\|qmlengine" "$logcat" 2>/dev/null || echo "0")
        local fatal_errors=$(grep -ci "fatal\|crash" "$logcat" 2>/dev/null || echo "0")
        local total_errors=$((qml_errors + qt_errors + fatal_errors))
        
        # Check for screenshot
        local screenshot=""
        local screenshot_file="$test_dir/screenshot-attempt-$attempt.png"
        if [ -f "$screenshot_file" ]; then
            screenshot="runtime-test/screenshot-attempt-$attempt.png"
        fi
        
        # Get fix log
        local fixes=""
        local fix_logs=$(find "$test_dir" -name "runtime-fix-*.txt" -newer "$logcat" 2>/dev/null | head -1)
        if [ -n "$fix_logs" ] && [ -f "$fix_logs" ]; then
            fixes=$(cat "$fix_logs" | head -20 | jq -Rs .)
        else
            fixes='""'
        fi
        
        local status="success"
        [ $total_errors -gt 0 ] && status="failed"
        
        cat << EOF
    {
      "buildId": "runtime-$build_id-attempt-$attempt",
      "version": "Runtime Test Cycle $attempt",
      "date": "$date",
      "status": "$status",
      "type": "runtime",
      "attempt": $attempt,
      "errors": {
        "qml": $qml_errors,
        "qt": $qt_errors,
        "fatal": $fatal_errors,
        "total": $total_errors
      },
      "logs": {
        "logcat": "runtime-test/$(basename "$logcat")",
        "fixes": $fixes
      },
      "screenshot": "$screenshot"
    }
EOF
        
        build_id=$((build_id + 1))
    done
}

# Parse build logs
parse_build_logs() {
    local self_heal_dir="$CI_REPORTS/self-heal"
    local builds=()
    
    if [ ! -d "$self_heal_dir" ]; then
        echo ""
        return
    fi
    
    # Find build logs
    local build_logs=$(find "$self_heal_dir" -name "build-*.log" 2>/dev/null | sort -r)
    
    local build_id=1
    
    for log in $build_logs; do
        local timestamp=$(stat -c %Y "$log" 2>/dev/null || echo "0")
        local date=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
        
        # Count errors
        local compile_errors=$(grep -ci "error:" "$log" 2>/dev/null || echo "0")
        local cmake_errors=$(grep -ci "cmake error" "$log" 2>/dev/null || echo "0")
        local total_errors=$((compile_errors + cmake_errors))
        
        local status="success"
        [ $total_errors -gt 0 ] && status="failed"
        
        cat << EOF
    {
      "buildId": "build-$build_id",
      "version": "Build #$build_id",
      "date": "$date",
      "status": "$status",
      "type": "build",
      "errors": {
        "compile": $compile_errors,
        "cmake": $cmake_errors,
        "total": $total_errors
      },
      "logs": {
        "build": "self-heal/$(basename "$log")"
      }
    }
EOF
        
        build_id=$((build_id + 1))
    done
}

# Generate JSON
generate_json() {
    cat > "$OUTPUT_JSON" << 'EOF'
{
  "generated": "$(date -Iseconds)",
  "project": "file_transfer_ovimage",
  "builds": [
EOF

    # Add runtime tests
    local runtime_data=$(parse_runtime_tests)
    if [ -n "$runtime_data" ]; then
        echo "$runtime_data" >> "$OUTPUT_JSON"
        
        # Check if we need comma separator
        local build_data=$(parse_build_logs)
        if [ -n "$build_data" ]; then
            echo "," >> "$OUTPUT_JSON"
        fi
    fi
    
    # Add build tests
    parse_build_logs >> "$OUTPUT_JSON"
    
    cat >> "$OUTPUT_JSON" << 'EOF'
  ]
}
EOF
}

# Main
echo "Generating test data JSON..."
generate_json
echo "Generated: $OUTPUT_JSON"
