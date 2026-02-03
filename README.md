# Bicep Function Unit Testing

Automated unit testing framework for Bicep functions using the `bicep console` stdin/stdout feature.

## Overview

Test your Bicep functions with a simple JSON-based test format. Define expected behavior, run tests locally or in CI/CD pipelines, and catch issues early.

**Quick facts:**
- 📝 JSON-based test format
- 🧪 11 different assertion types
- ⚡ Parallel test execution
- 🔗 Reference custom Bicep functions
- 🚀 CI/CD ready (GitHub Actions, Azure DevOps)
- 💻 Cross-platform (Linux, macOS, Windows)

## Getting Started

1. **[Quick Start Guide](./docs/quick-start.md)** - Install Bicep CLI and run your first test (5 minutes)
2. **[Create a Test File](./docs/test-files.md)** - Understand test file format and structure
3. **[Run Tests](./docs/script-parameters.md)** - Learn all command-line options

## Full Documentation

Complete documentation is in the [`docs/`](./docs/) folder:

| Topic | Description |
|-------|-------------|
| [**Quick Start**](./docs/quick-start.md) | Installation and first test |
| [**Test Files Overview**](./docs/test-files.md) | Test file concepts and organization |
| [**Test File Format**](./docs/test-json-format.md) | Complete format specification |
| [**Assertions Reference**](./docs/assertions.md) | All 11 assertion types with examples |
| [**Script Parameters**](./docs/script-parameters.md) | Command-line options for test runner |
| [**Bicep Functions**](./docs/bicep-functions.md) | How to reference and test custom functions |
| [**Best Practices**](./docs/best-practices.md) | Tips for effective testing |
| [**CI/CD Integration**](./docs/cicd-integration.md) | GitHub Actions and Azure DevOps setup |

## Project Structure

```
Bicep-Unit-Testing/
├── docs/                         # Complete documentation
├── bicep-functions/              # Custom Bicep function definitions
├── framework/                    # Test runner scripts
│   ├── run-tests.ps1            # PowerShell runner
│   └── run-tests.sh             # Bash runner
├── tests/                        # Test files (.bicep-test.json)
└── azure-devops/                 # Azure DevOps pipeline
```

## Prerequisites

- **Bicep CLI** v0.40.2 or later - [Installation Instructions](./docs/quick-start.md#installing-bicep-cli)
- **Bash** (Linux/macOS) or **PowerShell** (Windows)
- **jq** (Bash only, usually pre-installed)

## Quick Example

Create a test file `tests/hello.bicep-test.json`:

```json
{
  "description": "Test string concatenation",
  "tests": [
    {
      "name": "Concat two strings",
      "input": "concat('hello', ' ', 'world')",
      "shouldBe": "'hello world'"
    }
  ]
}
```

Run tests:

```powershell
# Windows
.\framework\run-tests.ps1

# Linux/macOS
./framework/run-tests.sh
```

Output:
```
✅ PASS: Concat two strings
Tests completed: 1 passed, 0 failed
```

## Key Links

- 📚 **[Complete Documentation](./docs/)** - All guides and references
- 🏃 **[Quick Start (5 min)](./docs/quick-start.md)** - Get started immediately
- 📋 **[Assertion Types](./docs/assertions.md)** - All 11 assertion types explained
- 🔧 **[Script Parameters](./docs/script-parameters.md)** - Runner options and configuration
- 🚀 **[CI/CD Integration](./docs/cicd-integration.md)** - GitHub Actions & Azure DevOps

## Features

✨ **Everything you need:**

- Multiple tests per file
- 11 flexible assertion types
- Reference custom Bicep functions
- Parallel execution for speed
- Detailed pass/fail reporting
- Cross-platform support
- Backward compatible

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License

See [LICENSE](./LICENSE) file for details.
