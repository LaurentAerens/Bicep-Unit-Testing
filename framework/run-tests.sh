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
    # Remove the WARNING line about experimental feature and normalize line endings
    # tr -d '\r' removes any carriage return characters (Windows CRLF -> LF)
    echo "$output" | tr -d '\r' | grep -v "WARNING: The 'console' CLI command is an experimental feature" | sed '/^$/d'
}

# Function to run a single test case
run_single_test() {
    # This function accepts either:
    # 1) A test JSON string (legacy behavior): run_single_test "$test_json" "$test_name" $test_index
    # 2) A test file path + test name + zero-based index: run_single_test "$test_file" "$test_name" $index
    local arg1="$1"
    local test_name="$2"
    local test_index="$3"
    
    # If arg1 is a file path and index is numeric, read fields directly from the test file to avoid jq parsing errors
    local input
    local bicep_file
    local function_call
    local should_be
    local should_not_be
    local should_contain
    local test_display_name

    if [ -f "$arg1" ] && [[ "$test_index" =~ ^[0-9]+$ ]]; then
        local test_file="$arg1"
        local idx="$test_index"
        input=$(jq -r ".tests[$idx].input // \"null\"" "$test_file")
        bicep_file=$(jq -r ".tests[$idx].bicepFile // \"null\"" "$test_file")
        function_call=$(jq -r ".tests[$idx].functionCall // \"null\"" "$test_file")
        should_be=$(jq -r ".tests[$idx].shouldBe // \"null\"" "$test_file")
        should_not_be=$(jq -r ".tests[$idx].shouldNotBe // \"null\"" "$test_file")
        should_contain=$(jq -r ".tests[$idx].shouldContain // \"null\"" "$test_file")
        test_display_name=$(jq -r ".tests[$idx].name // \"null\"" "$test_file")
    else
        # Legacy: arg1 contains the JSON test object as a string
        local test_json="$arg1"
        input=$(echo "$test_json" | jq -r '.input // "null"')
        bicep_file=$(echo "$test_json" | jq -r '.bicepFile // "null"')
        function_call=$(echo "$test_json" | jq -r '.functionCall // "null"')
        should_be=$(echo "$test_json" | jq -r '.shouldBe // "null"')
        should_not_be=$(echo "$test_json" | jq -r '.shouldNotBe // "null"')
        should_contain=$(echo "$test_json" | jq -r '.shouldContain // "null"')
        test_display_name=$(echo "$test_json" | jq -r '.name // "null"')
    fi
    
    if [ "$test_display_name" = "null" ]; then
        # if index is zero-based, present as 1-based in display
        display_index=$((test_index+1))
        test_display_name="Test $display_index"
    fi
    
    if [ "$QUIET_MODE" != "true" ]; then
        echo -e "  ${YELLOW}[$test_index]${NC} $test_display_name"
    fi
    
    # Determine input based on test format
    if [ "$bicep_file" != "null" ] && [ "$function_call" != "null" ]; then
        # Using bicepFile + functionCall format
        if [ ! -f "$bicep_file" ]; then
            echo -e "    ${RED}✗ FAILED${NC}"
            echo "    Error: Bicep file not found: $bicep_file"
            ((FAILED_TESTS++))
            return 1
        fi
        
        # Extract function definitions from the bicep file
        local bicep_content=$(cat "$bicep_file")
        
        # Combine function definitions with function call
        input=$(cat << BICEP_INPUT
$bicep_content
$function_call
BICEP_INPUT
)
        
        if [ "$VERBOSE" = "true" ]; then
            echo "    Bicep file: $bicep_file"
            echo "    Function call: $function_call"
        fi
    else
        # Using inline input format
        if [ "$input" = "null" ]; then
            echo -e "    ${RED}✗ FAILED${NC}"
            echo "    Error: Test must have either 'input' or 'bicepFile' + 'functionCall'"
            ((FAILED_TESTS++))
            return 1
        fi
        
        if [ "$VERBOSE" = "true" ]; then
            echo "    Input: $input"
        fi
    fi
    
    # Run bicep console
    local actual_output=$(echo "$input" | bicep console 2>&1)
    local bicep_exit_code=$?
    
    # Normalize outputs
    local actual=$(normalize_output "$actual_output")
    
    if [ "$VERBOSE" = "true" ]; then
        echo "    Actual: $actual"
    fi
    
    # Determine which assertion to use
    local passed=false
    local assertion_type=""
    local assertion_value=""
    
    if [ "$should_be" != "null" ]; then
        # shouldBe: exact match
        assertion_type="shouldBe"
        assertion_value=$(normalize_output "$should_be")
        if [ "$actual" = "$assertion_value" ]; then
            passed=true
        fi
    elif [ "$should_not_be" != "null" ]; then
        # shouldNotBe: must not match
        assertion_type="shouldNotBe"
        assertion_value=$(normalize_output "$should_not_be")
        if [ "$actual" != "$assertion_value" ]; then
            passed=true
        fi
    elif [ "$should_contain" != "null" ]; then
        # shouldContain: substring match
        assertion_type="shouldContain"
        assertion_value=$(normalize_output "$should_contain")
        if [[ "$actual" == *"$assertion_value"* ]]; then
            passed=true
        fi
    else
        echo -e "    ${RED}✗ FAILED${NC}"
        echo "    Error: Test must have one of: shouldBe, shouldNotBe, or shouldContain"
        ((FAILED_TESTS++))
        return 1
    fi
    
    # Report results
    if [ "$passed" = true ]; then
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "    ${GREEN}✓ PASSED${NC}"
        fi
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "    ${RED}✗ FAILED${NC}"
        case "$assertion_type" in
            shouldBe)
                echo "    Expected: $assertion_value"
                echo "    Actual:   $actual"
                ;;
            shouldNotBe)
                echo "    Should NOT be: $assertion_value"
                echo "    But actual was: $actual"
                ;;
            shouldContain)
                echo "    Should contain: $assertion_value"
                echo "    Actual:         $actual"
                ;;
        esac
        ((FAILED_TESTS++))
        return 1
    fi
}

# Function to run a test file (may contain multiple tests)
run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .bicep-test.json)
    
    if [ "$QUIET_MODE" != "true" ]; then
        echo -e "\n${YELLOW}Running test: $test_name${NC}"
    fi
    
    # Read test file
    local description=$(jq -r '.description // ""' "$test_file")
    
    if [ "$VERBOSE" = "true" ] && [ ! -z "$description" ]; then
        echo "  Description: $description"
    fi
    
    # Check if this is the new multi-test format or legacy format
    local has_tests_array=$(jq 'has("tests")' "$test_file")
    
    if [ "$has_tests_array" = "true" ]; then
        # New format: multiple tests in array
        local test_count=$(jq '.tests | length' "$test_file")
        
        if [ "$test_count" = "0" ]; then
            echo -e "  ${YELLOW}✗ WARNING: No tests defined in file${NC}"
            return 0
        fi
        
        for ((i=0; i<test_count; i++)); do
            ((TOTAL_TESTS++))
            # Pass the test file and zero-based index to avoid serialization/parsing issues
            run_single_test "$test_file" "$test_name" $i || true
        done
    else
        # Legacy format: single test in root
        ((TOTAL_TESTS++))
        
        # Convert legacy format to new format for processing
        local input=$(jq -r '.input // "null"' "$test_file")
        local bicep_file=$(jq -r '.bicepFile // "null"' "$test_file")
        local function_call=$(jq -r '.functionCall // "null"' "$test_file")
        local expected=$(jq -r '.expected' "$test_file")
        
        # Create a JSON object with legacy values mapped to new format
        local legacy_test=$(cat << LEGACY_JSON
{
  "input": $([[ "$input" != "null" ]] && echo "\"$input\"" || echo "null"),
  "bicepFile": $([[ "$bicep_file" != "null" ]] && echo "\"$bicep_file\"" || echo "null"),
  "functionCall": $([[ "$function_call" != "null" ]] && echo "\"$function_call\"" || echo "null"),
  "shouldBe": "$expected"
}
LEGACY_JSON
)
        
        run_single_test "$legacy_test" "$test_name" 1 || true
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
    run_test "$test_file"
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
