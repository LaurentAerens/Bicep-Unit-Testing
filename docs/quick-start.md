# Quick Start Guide

Get up and running with Bicep unit testing in minutes.

## Prerequisites

- [Bicep CLI](https://github.com/Azure/bicep) v0.40.0 or later (with console stdin/stdout support)
- Bash (for Linux/macOS) or PowerShell (for Windows)
- `jq` (for Bash script only - usually pre-installed on most systems)

## Installing Bicep CLI

### Linux

```bash
curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
chmod +x bicep
sudo mv bicep /usr/local/bin/bicep
```

### macOS

```bash
brew tap azure/bicep
brew install bicep
```

### Windows (PowerShell)

```powershell
$InstallPath = "C:\bicep"
New-Item -ItemType Directory -Force -Path $InstallPath
Invoke-WebRequest -Uri "https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe" -OutFile "$InstallPath\bicep.exe"
$env:PATH = "$InstallPath;$env:PATH"
```

## Running Your First Tests

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/Bicep-Unit-Testing.git
cd Bicep-Unit-Testing
```

### 2. Run the Test Suite

**Windows (PowerShell):**
```powershell
.\run-tests.ps1
```

**Linux/macOS (Bash):**
```bash
./run-tests.sh
```

You should see output like:
```
Running tests...
✅ Test 1: String concatenation passed
✅ Test 2: Array length validation passed
...
Tests completed: 50 passed, 0 failed
```

## Creating Your First Test

### 1. Create a Test File

Create `tests/my-first-test.bicep-test.json`:

```json
{
  "description": "My first test suite",
  "tests": [
    {
      "name": "Concatenate strings",
      "input": "concat('hello', ' ', 'world')",
      "shouldBe": "'hello world'"
    },
    {
      "name": "Check array length",
      "input": "length([1, 2, 3])",
      "shouldBe": "3"
    }
  ]
}
```

### 2. Run Your Tests

```powershell
# Windows
.\run-tests.ps1 -Verbose

# Linux/macOS
./run-tests.sh -v
```

## Next Steps

- Learn about all [Assertion Types](./assertions.md)
- Explore [Test File Format](./test-json-format.md) for advanced options
- Discover how to [Load Bicep Functions](./bicep-functions.md)
- Check [Script Parameters](./script-parameters.md) for all runner options
