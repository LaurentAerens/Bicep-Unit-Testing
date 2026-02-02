# Bicep Function Unit Testing

Automated unit testing framework for Bicep functions using the new `bicep console` stdin/stdout feature. This allows you to test custom Bicep functions with known inputs and validate their outputs in CI/CD pipelines and local development environments.

## Features

- ✅ **Automated Testing**: Run all your Bicep function tests automatically
- ✅ **CI/CD Ready**: GitHub Actions workflow included for continuous testing
- ✅ **Cross-Platform**: Works on Linux, macOS, and Windows
- ✅ **Simple Test Format**: JSON-based test definitions
- ✅ **Detailed Reporting**: Clear pass/fail results with expected vs actual comparisons
- ✅ **Parallel Execution**: Fast test execution
- ✅ **Verbose Mode**: Optional detailed output for debugging

## Prerequisites

- [Bicep CLI](https://github.com/Azure/bicep) v0.40.0 or later (with console stdin/stdout support)
- Bash (for Linux/macOS) or PowerShell (for Windows)
- `jq` (for Bash script only - usually pre-installed on most systems)

## Quick Start

### 1. Install Bicep CLI

**Linux:**
```bash
curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
chmod +x bicep
sudo mv bicep /usr/local/bin/bicep
```

**macOS:**
```bash
brew tap azure/bicep
brew install bicep
```

**Windows (PowerShell):**
```powershell
$InstallPath = "C:\bicep"
New-Item -ItemType Directory -Force -Path $InstallPath
Invoke-WebRequest -Uri "https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe" -OutFile "$InstallPath\bicep.exe"
$env:PATH = "$InstallPath;$env:PATH"
```

### 2. Create Test Files

Create test files in the `tests` directory with the `.bicep-test.json` extension:

```json
{
  "description": "Test concat function with strings",
  "input": "concat('hello', ' ', 'world')",
  "expected": "'hello world'"
}
```

### 3. Run Tests

**Linux/macOS:**
```bash
./run-tests.sh
```

**Windows:**
```powershell
.\run-tests.ps1
```

## Test File Format

Test files must be named with the `.bicep-test.json` extension and contain:

```json
{
  "description": "Human-readable test description",
  "input": "Bicep expression to evaluate",
  "expected": "Expected output from bicep console"
}
```

### Example Test Files

**Testing parseCidr function:**
```json
{
  "description": "Test parseCidr function with /20 CIDR block",
  "input": "parseCidr('10.144.0.0/20')",
  "expected": "{\n  network: '10.144.0.0'\n  netmask: '255.255.240.0'\n  broadcast: '10.144.15.255'\n  firstUsable: '10.144.0.1'\n  lastUsable: '10.144.15.254'\n  cidr: 20\n}"
}
```

**Testing length function:**
```json
{
  "description": "Test length function with an array",
  "input": "length([1, 2, 3])",
  "expected": "3"
}
```

**Testing string functions:**
```json
{
  "description": "Test toUpper function",
  "input": "toUpper('bicep')",
  "expected": "'BICEP'"
}
```

## Usage

### Basic Usage

Run all tests in the default `./tests` directory:

```bash
# Linux/macOS
./run-tests.sh

# Windows
.\run-tests.ps1
```

### Advanced Options

**Specify a different test directory:**
```bash
# Linux/macOS
./run-tests.sh -d ./my-custom-tests

# Windows
.\run-tests.ps1 -TestDir ./my-custom-tests
```

**Enable verbose output:**
```bash
# Linux/macOS
./run-tests.sh -v

# Windows
.\run-tests.ps1 -VerboseOutput
```

**Quiet mode (summary only):**
```bash
# Linux/macOS
./run-tests.sh -q

# Windows
.\run-tests.ps1 -Quiet
```

**Help:**
```bash
# Linux/macOS
./run-tests.sh -h

# Windows
Get-Help .\run-tests.ps1
```

## CI/CD Integration

### GitHub Actions

A GitHub Actions workflow is included in `.github/workflows/test.yml` that automatically:
- Runs tests on Linux, Windows, and macOS
- Installs Bicep CLI
- Executes all tests
- Reports results

The workflow runs on:
- Push to `main` or `master` branches
- Pull requests to `main` or `master` branches
- Manual workflow dispatch

### Other CI/CD Systems

The test runners are simple scripts that return:
- Exit code 0 on success (all tests pass)
- Exit code 1 on failure (one or more tests fail)

Example integration:

**Azure DevOps:**
```yaml
- script: |
    ./run-tests.sh
  displayName: 'Run Bicep Function Tests'
```

**GitLab CI:**
```yaml
test:
  script:
    - ./run-tests.sh
```

**Jenkins:**
```groovy
sh './run-tests.sh'
```

## Example Test Scenarios

### Testing Custom Functions

If you have custom Bicep functions, you can test them:

```json
{
  "description": "Test custom IP calculation",
  "input": "parseCidr('192.168.1.0/24')",
  "expected": "{\n  network: '192.168.1.0'\n  netmask: '255.255.255.0'\n  broadcast: '192.168.1.255'\n  firstUsable: '192.168.1.1'\n  lastUsable: '192.168.1.254'\n  cidr: 24\n}"
}
```

### Testing Complex Expressions

```json
{
  "description": "Test nested function calls",
  "input": "length(concat([1, 2], [3, 4]))",
  "expected": "4"
}
```

### Testing Edge Cases

```json
{
  "description": "Test empty array length",
  "input": "length([])",
  "expected": "0"
}
```

## How It Works

1. The test runner reads all `.bicep-test.json` files from the test directory
2. For each test:
   - Extracts the `input` expression
   - Pipes it to `bicep console` via stdin
   - Captures the output from stdout
   - Compares the output with the `expected` value
   - Reports pass/fail status
3. Generates a summary report with total, passed, and failed tests

## Tips and Best Practices

1. **Keep tests focused**: One test per function/scenario
2. **Use descriptive names**: Name test files clearly (e.g., `parseCidr-ipv4.bicep-test.json`)
3. **Test edge cases**: Include tests for empty inputs, nulls, and boundary conditions
4. **Document complex tests**: Use the `description` field to explain what you're testing
5. **Version control**: Commit your test files to track changes over time
6. **Run locally first**: Test your changes locally before pushing to CI/CD

## Troubleshooting

### Tests fail with "bicep: command not found"

Install the Bicep CLI following the installation instructions above.

### Tests fail with "jq: command not found" (Bash only)

Install jq:
- **Ubuntu/Debian**: `sudo apt-get install jq`
- **macOS**: `brew install jq`
- **Other**: See [jq installation guide](https://stedolan.github.io/jq/download/)

Or use the PowerShell version which doesn't require jq.

### Expected output doesn't match

Run the test with verbose mode to see the actual vs expected output:
```bash
./run-tests.sh -v
```

Then update your test file with the correct expected output.

### Warnings about experimental feature

The warning about `bicep console` being experimental is normal and is filtered out during test comparison.

## Contributing

To add more example tests:
1. Create a new `.bicep-test.json` file in the `tests` directory
2. Define your input and expected output
3. Run the tests to verify
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to the Azure Bicep team for adding stdin/stdout support to `bicep console`
- Inspired by the need for automated testing of infrastructure as code
