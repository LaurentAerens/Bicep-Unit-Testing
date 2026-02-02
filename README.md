# Bicep Function Unit Testing

Automated unit testing framework for Bicep functions using the new `bicep console` stdin/stdout feature. This allows you to test custom Bicep functions with known inputs and validate their outputs in CI/CD pipelines and local development environments.

## Features

- ✅ **Automated Testing**: Run all your Bicep function tests automatically
- ✅ **Multiple Tests per File**: Define multiple test cases in a single test file
- ✅ **Flexible Assertions**: Use `shouldBe`, `shouldNotBe`, or `shouldContain` assertion types
- ✅ **Bicep File References**: Reference custom functions from .bicep files
- ✅ **CI/CD Ready**: GitHub Actions and Azure DevOps pipelines included
- ✅ **Cross-Platform**: Works on Linux, macOS, and Windows
- ✅ **Simple Test Format**: JSON-based test definitions
- ✅ **Detailed Reporting**: Clear pass/fail results with expected vs actual comparisons
- ✅ **Parallel Execution**: Fast test execution
- ✅ **Verbose Mode**: Optional detailed output for debugging
- ✅ **Backward Compatible**: Legacy single-test format still supported

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

Test files support two formats: a new multi-test format and a legacy single-test format (still supported).

#### New Format: Multiple Tests with Flexible Assertions

Create test files in the `tests` directory with the `.bicep-test.json` extension:

```json
{
  "description": "Test suite for string functions",
  "tests": [
    {
      "name": "String concatenation should match exact output",
      "input": "concat('hello', ' ', 'world')",
      "shouldBe": "'hello world'"
    },
    {
      "name": "Array length should not be zero",
      "input": "length([1, 2, 3])",
      "shouldNotBe": "0"
    },
    {
      "name": "toLower should contain lowercase text",
      "input": "toLower('HELLO')",
      "shouldContain": "hello"
    }
  ]
}
```

**Assertion Types:**
- `shouldBe`: Exact match - test passes if output equals this value
- `shouldNotBe`: Negation - test passes if output does NOT equal this value
- `shouldContain`: Substring match - test passes if output contains this text

#### Legacy Format: Single Test (Still Supported)

For backward compatibility, single-test files are still supported:

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

Test files must be named with the `.bicep-test.json` extension. Two formats are supported:

### New Format: Multiple Tests with Assertions

The recommended format allows multiple test cases in a single file with flexible assertion types:

```json
{
  "description": "Description of the test suite",
  "tests": [
    {
      "name": "Test case name",
      "input": "Bicep expression to evaluate",
      "shouldBe": "Expected exact output"
    },
    {
      "name": "Another test",
      "bicepFile": "path/to/functions.bicep",
      "functionCall": "myFunction(param)",
      "shouldNotBe": "Value it should NOT equal"
    },
    {
      "name": "Third test",
      "input": "someFunction()",
      "shouldContain": "Text that should appear in output"
    }
  ]
}
```

**Test Properties:**
- `name` (optional): Human-readable test name
- `input`: Inline Bicep expression to evaluate (use this OR bicepFile+functionCall)
- `bicepFile`: Path to .bicep file with custom functions (use with functionCall)
- `functionCall`: Function call expression when using bicepFile

**Assertion Types (choose one per test):**
- `shouldBe`: Exact match - output must equal this value exactly
- `shouldNotBe`: Negation - output must NOT equal this value
- `shouldContain`: Substring match - output must contain this text

### Legacy Format: Single Test

For backward compatibility, the original single-test format is still supported:

```json
{
  "description": "Test description",
  "input": "Bicep expression to evaluate",
  "expected": "Expected output"
}
```

Or with Bicep file reference:

```json
{
  "description": "Test description",
  "bicepFile": "path/to/functions.bicep",
  "functionCall": "myFunction(param)",
  "expected": "Expected output"
}
```

**Benefits of Bicep File Reference:**
- Separate function definitions from test cases
- Reuse function definitions across multiple tests
- Test custom Bicep functions without repeating definitions
- Better organization for complex function libraries

### Example Test Files

**Testing multiple assertions in one file:**
```json
{
  "description": "Comprehensive string function tests",
  "tests": [
    {
      "name": "Exact match test",
      "input": "toUpper('bicep')",
      "shouldBe": "'BICEP'"
    },
    {
      "name": "Should not be empty",
      "input": "concat('hello', 'world')",
      "shouldNotBe": "''"
    },
    {
      "name": "Contains substring",
      "input": "toLower('HELLO WORLD')",
      "shouldContain": "world"
    }
  ]
}
```

**Testing parseCidr function:**
```json
{
  "description": "Test parseCidr function with /20 CIDR block",
  "tests": [
    {
      "name": "parseCidr returns correct structure",
      "input": "parseCidr('10.144.0.0/20')",
      "shouldContain": "network: '10.144.0.0'"
    },
    {
      "name": "parseCidr network should not be empty",
      "input": "parseCidr('10.144.0.0/20')",
      "shouldNotBe": "{}"
    }
  ]
}
```

**Testing custom functions from Bicep file:**
```json
{
  "description": "Test custom math functions",
  "tests": [
    {
      "name": "Add function",
      "bicepFile": "bicep-functions/math-functions.bicep",
      "functionCall": "add(5, 3)",
      "shouldBe": "8"
    },
    {
      "name": "Multiply result should not be zero",
      "bicepFile": "bicep-functions/math-functions.bicep",
      "functionCall": "multiply(4, 5)",
      "shouldNotBe": "0"
    }
  ]
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

### Azure DevOps

An Azure DevOps pipeline is included in `azure-pipelines.yml` that automatically:
- Runs tests on Linux, Windows, and macOS
- Installs Bicep CLI
- Executes all tests
- Publishes test results

The pipeline runs on:
- Push to `main` or `master` branches
- Pull requests to `main` or `master` branches

**Setup Instructions:**
1. Go to Azure DevOps → Pipelines → New Pipeline
2. Select your repository
3. Choose "Existing Azure Pipelines YAML file"
4. Select `/azure-pipelines.yml`
5. Run the pipeline

### Other CI/CD Systems

The test runners are simple scripts that return:
- Exit code 0 on success (all tests pass)
- Exit code 1 on failure (one or more tests fail)

Example integration:

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

### Testing with Multiple Assertions

Combine different assertion types to thoroughly test your functions:

```json
{
  "description": "Comprehensive validation tests",
  "tests": [
    {
      "name": "Result should be exact value",
      "input": "length([1, 2, 3])",
      "shouldBe": "3"
    },
    {
      "name": "Result should not be zero",
      "input": "length([1, 2, 3])",
      "shouldNotBe": "0"
    },
    {
      "name": "Output should contain specific text",
      "input": "parseCidr('192.168.1.0/24')",
      "shouldContain": "network: '192.168.1.0'"
    }
  ]
}
```

### Testing Built-in Functions

Test any built-in Bicep function:

```json
{
  "description": "Built-in function tests",
  "tests": [
    {
      "name": "String replacement",
      "input": "replace('hello world', 'world', 'bicep')",
      "shouldBe": "'hello bicep'"
    },
    {
      "name": "Empty array check",
      "input": "length([])",
      "shouldNotBe": "5"
    },
    {
      "name": "Unique string generation",
      "input": "uniqueString('test')",
      "shouldNotBe": "''"
    }
  ]
}
```

### Testing Custom Functions

**Step 1:** Create a Bicep file with your custom functions

**bicep-functions/naming.bicep:**
```bicep
// Function to generate standardized resource names
func getResourceName(resourceType string, appName string, env string) string => 
  toLower('${resourceType}-${appName}-${env}')

// Function to validate environment
func isValidEnvironment(env string) bool => 
  contains(['dev', 'test', 'prod'], env)
```

**Step 2:** Create tests with multiple assertions

**tests/naming-tests.bicep-test.json:**
```json
{
  "description": "Naming convention validation tests",
  "tests": [
    {
      "name": "Resource name format for dev",
      "bicepFile": "bicep-functions/naming.bicep",
      "functionCall": "getResourceName('storage', 'myapp', 'dev')",
      "shouldBe": "'storage-myapp-dev'"
    },
    {
      "name": "Resource name should contain app name",
      "bicepFile": "bicep-functions/naming.bicep",
      "functionCall": "getResourceName('storage', 'myapp', 'prod')",
      "shouldContain": "myapp"
    },
    {
      "name": "Valid environment check",
      "bicepFile": "bicep-functions/naming.bicep",
      "functionCall": "isValidEnvironment('prod')",
      "shouldBe": "true"
    },
    {
      "name": "Invalid environment check",
      "bicepFile": "bicep-functions/naming.bicep",
      "functionCall": "isValidEnvironment('staging')",
      "shouldNotBe": "true"
    }
  ]
}
```

### Testing Negative Cases

Use `shouldNotBe` to test what values should NOT be returned:

```json
{
  "description": "Negative test cases",
  "tests": [
    {
      "name": "Empty array should not have positive length",
      "input": "length([])",
      "shouldNotBe": "5"
    },
    {
      "name": "Result should not be null",
      "input": "concat('a', 'b')",
      "shouldNotBe": "null"
    },
    {
      "name": "Function should not return empty string",
      "input": "uniqueString('input')",
      "shouldNotBe": "''"
    }
  ]
}
```

### Testing Partial Matches

Use `shouldContain` for complex objects or when you only care about part of the output:

```json
{
  "description": "Partial match tests",
  "tests": [
    {
      "name": "parseCidr should include network field",
      "input": "parseCidr('10.0.0.0/16')",
      "shouldContain": "network: '10.0.0.0'"
    },
    {
      "name": "Output should contain expected substring",
      "input": "toLower('HELLO WORLD')",
      "shouldContain": "hello"
    }
  ]
}
```

## How It Works

1. The test runner reads all `.bicep-test.json` files from the test directory
2. For each test:
   - **Inline format**: Extracts the `input` expression
   - **Bicep file format**: Loads function definitions from `bicepFile` and combines with `functionCall`
   - Pipes the expression to `bicep console` via stdin
   - Captures the output from stdout
   - Compares the output with the `expected` value
   - Reports pass/fail status
3. Generates a summary report with total, passed, and failed tests

## Tips and Best Practices

1. **Group related tests**: Use the multi-test format to group related test cases in one file
2. **Use descriptive names**: Give each test a clear `name` field to identify what's being tested
3. **Choose the right assertion**: 
   - Use `shouldBe` for exact matches
   - Use `shouldNotBe` for negative tests and exclusions
   - Use `shouldContain` for partial matches or complex objects
4. **Test edge cases**: Include tests for empty inputs, nulls, and boundary conditions
5. **Document complex tests**: Use the `description` field at the suite level for context
6. **Version control**: Commit your test files to track changes over time
7. **Run locally first**: Test your changes locally before pushing to CI/CD
8. **Combine assertions**: Test the same function with different assertion types for thorough coverage

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
