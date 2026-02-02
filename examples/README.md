# Example Test Files

This directory contains example test files to help you get started with Bicep function unit testing.

## Running Examples

To run these example tests:

```bash
# Linux/macOS
./run-tests.sh -d ./examples

# Windows
.\run-tests.ps1 -TestDir ./examples
```

## Creating Your Own Tests

1. Copy one of these examples to the `tests` directory
2. Modify the `input` and `expected` values
3. Run the tests

You can also use the helper scripts to get the expected output:

```bash
# Linux/macOS
./get-expected-output.sh "your-bicep-expression"

# Windows
.\get-expected-output.ps1 "your-bicep-expression"
```

## Test File Structure

Each test file should have:
- **description**: What you're testing
- **input**: The Bicep expression to evaluate
- **expected**: The expected output from bicep console

## More Examples

See the `tests` directory for more working examples of various Bicep functions.
