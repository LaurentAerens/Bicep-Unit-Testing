# Bicep Unit Testing Documentation

Welcome to the comprehensive documentation for the Bicep Unit Testing framework. Here you'll find detailed guides for all aspects of the testing system.

## Quick Navigation

### Getting Started
- **[Installation & Quick Start](./quick-start.md)** - Install dependencies and run your first tests
- **[Test Files Overview](./test-files.md)** - Understand the test file format and structure

### Core Documentation
- **[Assertion Types Reference](./assertions.md)** - All 11 assertion types with examples
- **[Test File Format](./test-json-format.md)** - Detailed specification of test file structure
- **[Script Parameters](./script-parameters.md)** - Command-line options for the test runner
- **[Loading Bicep Functions](./bicep-functions.md)** - How to reference and use custom Bicep functions

### Advanced Topics
- **[Best Practices](./best-practices.md)** - Tips and patterns for effective testing
- **[CI/CD Integration](./cicd-integration.md)** - Using with GitHub Actions and Azure DevOps

### Project Structure
```
Bicep-Unit-Testing/
├── docs/                         # Documentation (you are here)
├── .github/workflows/            # CI workflows
├── azure-devops/                 # Azure DevOps pipeline
├── bicep-functions/              # Custom Bicep function definitions
├── tests/                        # Test files and examples
├── framework/                    # Test runner scripts (use this script in your repo to unit test your Bicep functions)
└── README.md                     # Main project summary
```

## Key Features

- ✅ **Automated Testing** - Run all Bicep function tests automatically
- ✅ **Multiple Tests per File** - Define multiple test cases in a single file
- ✅ **11 Assertion Types** - Flexible validation options for comprehensive coverage
- ✅ **Custom Bicep Functions** - Reference and test your own function definitions
- ✅ **CI/CD Ready** - GitHub Actions and Azure DevOps pipelines included
- ✅ **Cross-Platform** - Works on Linux, macOS, and Windows
- ✅ **Parallel Execution** - Fast test execution with optional parallelization
- ✅ **Detailed Reporting** - Clear pass/fail results with expected vs actual comparisons

## What are you trying to do?

- **Running tests?** → Start with [Script Parameters](./script-parameters.md)
- **Writing tests?** → Go to [Test File Format](./test-json-format.md)
- **Using custom functions?** → See [Loading Bicep Functions](./bicep-functions.md)
- **Need help choosing assertions?** → Check [Assertion Types](./assertions.md)
- **Setting up CI/CD?** → Read [CI/CD Integration](./cicd-integration.md)
