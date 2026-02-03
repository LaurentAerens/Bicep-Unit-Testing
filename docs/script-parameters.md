# Script Parameters and Options

Complete reference for running the test runner with various command-line options.

## Windows PowerShell

### Basic Usage

```powershell
# Run all tests in default location
# Adjust path if run-tests.ps1 is in a different location
.\run-tests.ps1

# Run all tests with verbose output
.\run-tests.ps1 -Verbose

# Run tests in quiet mode (summary only)
.\run-tests.ps1 -Quiet
```

### Command-Line Parameters

#### -Parallel
Enables parallel test execution using all available CPU cores.

**Type**: Switch (boolean)
**Default**: $false (sequential execution)

```powershell
# Run tests in parallel using all cores
.\run-tests.ps1 -Parallel

# Equivalent to running with default concurrency
.\run-tests.ps1 -Parallel -MaxParallelJobs $env:NUMBER_OF_PROCESSORS
```

**Benefits**:
- Significantly faster execution for large test suites
- Automatically uses all available CPU cores
- Can be combined with `-MaxParallelJobs` to limit concurrency

#### -MaxParallelJobs
Limits the number of concurrent test jobs when using `-Parallel`.

**Type**: Integer
**Default**: Number of CPU cores (when `-Parallel` is used)
**Range**: 1 to 128

```powershell
# Run tests in parallel with max 4 concurrent jobs
.\run-tests.ps1 -Parallel -MaxParallelJobs 4

# Run tests in parallel with max 8 concurrent jobs
.\run-tests.ps1 -Parallel -MaxParallelJobs 8
```

**Use cases**:
- Limit concurrency on resource-constrained systems
- Prevent system overload on shared machines
- Improve readability of output when debugging

#### -Verbose
Shows detailed output including inputs and actual results for each test.

**Type**: Switch (boolean)
**Default**: $false

```powershell
# Show detailed test execution information
.\run-tests.ps1 -Verbose

# Combine with other options
.\run-tests.ps1 -Parallel -MaxParallelJobs 4 -Verbose
```

**Output includes**:
- Test name and description
- Input Bicep expression
- Expected output
- Actual output
- Pass/fail status

#### -Quiet
Suppresses individual test output and shows only the summary.

**Type**: Switch (boolean)
**Default**: $false

```powershell
# Run tests with summary only
.\run-tests.ps1 -Quiet

# Useful for CI/CD where you only want final results
.\run-tests.ps1 -Parallel -Quiet
```

**Output shows**:
- Total tests run
- Number of passed tests
- Number of failed tests
- Overall pass/fail

#### -TestDir
Specifies a custom directory for test discovery instead of the default `./tests`.

**Type**: String (path)
**Default**: `./tests`

```powershell
# Run tests from custom directory
.\run-tests.ps1 -TestDir ./my-custom-tests

# Run tests from a subdirectory
.\run-tests.ps1 -TestDir ./tests/unit

# Use absolute path
.\run-tests.ps1 -TestDir C:\full\path\to\tests
```

**Use cases**:
- Testing a subset of tests
- Running tests from different project locations
- Organizing tests by category in different folders

### Parameter Combinations

#### Example 1: Fast CI/CD Run
```powershell
# Parallel execution with quiet output for CI/CD pipelines
.\run-tests.ps1 -Parallel -Quiet
```

#### Example 2: Development with Detailed Output
```powershell
# Sequential with verbose output for debugging
.\run-tests.ps1 -Verbose
```

#### Example 3: Debug Specific Tests
```powershell
# Run only tests in a specific directory with details
.\run-tests.ps1 -TestDir ./tests/advanced -Verbose
```

#### Example 4: Limited Parallelism
```powershell
# Parallel with limited concurrency on a busy system
.\run-tests.ps1 -Parallel -MaxParallelJobs 2 -Verbose
```

## Linux/macOS Bash

### Basic Usage

```bash
# Run all tests
./run-tests.sh

# Run with verbose output
./run-tests.sh -v

# Run in quiet mode
./run-tests.sh -q
```

### Command-Line Parameters (Bash)

#### -v / --verbose
Verbose output with test details.

```bash
./run-tests.sh -v
./run-tests.sh --verbose
```

#### -q / --quiet
Quiet mode showing only summary.

```bash
./run-tests.sh -q
./run-tests.sh --quiet
```

#### -d / --directory
Custom test directory.

```bash
./run-tests.sh -d ./my-tests
./run-tests.sh --directory ./my-tests
```

#### -h / --help
Show help information.

```bash
./run-tests.sh -h
./run-tests.sh --help
```

## Environment Variables

Both PowerShell and Bash runners respect these environment variables:

### BICEP_CLI
Path to the Bicep CLI executable.

```powershell
# PowerShell
$env:BICEP_CLI = "C:\tools\bicep.exe"
.\run-tests.ps1

# Bash
export BICEP_CLI=/usr/local/bin/bicep
./run-tests.sh
```

**Default**: Looks for `bicep` in system PATH

### TEST_DIR
Default test directory (can be overridden by `-TestDir` parameter).

```powershell
# PowerShell
$env:TEST_DIR = "./my-tests"
.\run-tests.ps1

# Bash
export TEST_DIR=./my-tests
./run-tests.sh
```

**Default**: `./tests`

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All tests passed |
| `1` | One or more tests failed |
| `2` | Framework error (invalid options, missing dependencies, etc.) |
| `3` | No tests found |

### Using Exit Codes in CI/CD

```powershell
# PowerShell example
.\run-tests.ps1 -Parallel
if ($LASTEXITCODE -ne 0) {
    Write-Error "Tests failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
```

```bash
# Bash example
./run-tests.sh
if [ $? -ne 0 ]; then
    echo "Tests failed"
    exit 1
fi
```

## Output Format

### Standard Output

```
Running tests from: ./tests

[01/50] ✅ PASS: String concatenation
[02/50] ✅ PASS: Array length validation
[03/50] ❌ FAIL: Invalid function call
...
[50/50] ✅ PASS: Complex subnet calculation

================================
Test Results Summary
================================
Total:  50 tests
Passed: 48 tests ✅
Failed: 2 tests ❌
Success Rate: 96%
```

### Verbose Output

```
[01/50] Test: String concatenation
        Input: concat('hello', 'world')
        Expected: 'helloworld'
        Actual: 'helloworld'
        Status: ✅ PASS

[02/50] Test: Array length validation
        Input: length([1, 2, 3])
        Expected: 3
        Actual: 3
        Status: ✅ PASS
```

### Quiet Output

```
Running tests from: ./tests

================================
Test Results Summary
================================
Total:  50 tests
Passed: 48 tests ✅
Failed: 2 tests ❌
Success Rate: 96%
```

## CI/CD Integration

See [CI/CD Integration](./cicd-integration.md) for examples of using these parameters in GitHub Actions and Azure DevOps pipelines.

## Troubleshooting

### Tests Not Found
```powershell
# Verify test directory exists
Test-Path ./tests

# List test files
Get-ChildItem -Path ./tests -Filter *.bicep-test.json -Recurse

# Run with custom directory
.\run-tests.ps1 -TestDir ./tests
```

### Bicep CLI Not Found
```powershell
# Check Bicep installation
bicep --version

# Specify explicit path if needed
$env:BICEP_CLI = "C:\path\to\bicep.exe"
.\run-tests.ps1
```

### Slow Test Execution
```powershell
# Use parallel execution
.\run-tests.ps1 -Parallel

# Check system resources
Get-Process | Sort-Object -Property WorkingSet64 -Descending | Select-Object -First 5
```

## Performance Tips

1. **Use `-Parallel` for large test suites** - Can reduce execution time by 50-80%
2. **Use `-Quiet` for CI/CD** - Reduces output overhead
3. **Limit `-MaxParallelJobs` on constrained systems** - Prevents resource exhaustion
4. **Use `-TestDir` to test subsets** - Run only relevant tests during development
5. **Combine options wisely** - `-Parallel -Quiet` is optimal for CI/CD

## See Also

- [Running Tests](./quick-start.md#running-your-first-tests)
- [CI/CD Integration](./cicd-integration.md)
- [Test Files Overview](./test-files.md)
