#!/bin/bash

# Bicep Function Unit Test Runner
# This script runs unit tests for Bicep functions using the bicep console feature

# Don't exit on error - we want to run all tests
set -u

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
TEST_DIR="${TEST_DIR:-./tests}"
VERBOSE="${VERBOSE:-false}"
QUIET_MODE="${QUIET_MODE:-false}"

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run Bicep function unit tests using bicep console.

OPTIONS:
    -d, --test-dir <dir>    Directory containing test files (default: ./tests)
    -v, --verbose           Enable verbose output
    -q, --quiet             Quiet mode - only show summary
    -h, --help              Show this help message

EXAMPLES:
    $0                      Run all tests in ./tests directory
    $0 -d ./my-tests        Run tests from ./my-tests directory
    $0 -v                   Run tests with verbose output

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--test-dir)
            TEST_DIR="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if bicep is installed
if ! command -v bicep &> /dev/null; then
    echo -e "${RED}Error: bicep CLI is not installed or not in PATH${NC}"
    exit 1
fi

# Check if test directory exists
if [ ! -d "$TEST_DIR" ]; then
    echo -e "${RED}Error: Test directory '$TEST_DIR' does not exist${NC}"
    exit 1
fi

# Function to normalize output for comparison
normalize_output() {
    local output="$1"
    # Remove the WARNING line about experimental feature
    echo "$output" | grep -v "WARNING: The 'console' CLI command is an experimental feature" | sed '/^$/d'
}

# Function to run a single test
run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .bicep-test.json)
    
    if [ "$QUIET_MODE" != "true" ]; then
        echo -e "\n${YELLOW}Running test: $test_name${NC}"
    fi
    
    # Read test file
    local input=$(jq -r '.input' "$test_file")
    local expected=$(jq -r '.expected' "$test_file")
    local description=$(jq -r '.description // ""' "$test_file")
    
    if [ "$VERBOSE" = "true" ] && [ ! -z "$description" ]; then
        echo "  Description: $description"
    fi
    
    if [ "$VERBOSE" = "true" ]; then
        echo "  Input: $input"
    fi
    
    # Run bicep console
    local actual_output=$(echo "$input" | bicep console 2>&1)
    local bicep_exit_code=$?
    
    # Normalize outputs
    local actual=$(normalize_output "$actual_output")
    local expected_normalized=$(normalize_output "$expected")
    
    if [ "$VERBOSE" = "true" ]; then
        echo "  Expected: $expected_normalized"
        echo "  Actual: $actual"
    fi
    
    # Compare outputs
    if [ "$actual" = "$expected_normalized" ]; then
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "  ${GREEN}✓ PASSED${NC}"
        fi
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC}"
        echo "  Expected: $expected_normalized"
        echo "  Actual:   $actual"
        ((FAILED_TESTS++))
        return 1
    fi
}

# Main execution
echo "================================================"
echo "Bicep Function Unit Test Runner"
echo "================================================"
echo "Test directory: $TEST_DIR"
echo ""

# Find all test files
TEST_FILES=$(find "$TEST_DIR" -name "*.bicep-test.json" 2>/dev/null | sort)

if [ -z "$TEST_FILES" ]; then
    echo -e "${YELLOW}No test files found in $TEST_DIR${NC}"
    echo "Test files should be named *.bicep-test.json"
    exit 0
fi

# Run all tests
for test_file in $TEST_FILES; do
    ((TOTAL_TESTS++))
    run_test "$test_file" || true
done

# Print summary
echo ""
echo "================================================"
echo "Test Summary"
echo "================================================"
echo "Total tests:  $TOTAL_TESTS"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo "================================================"

# Exit with appropriate code
if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
else
    exit 0
fi
