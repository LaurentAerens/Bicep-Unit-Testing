# Test Files Overview

This document provides a high-level overview of test files. For detailed specifications, see [Test File Format](./test-json-format.md).

## What is a Test File?

A test file is a JSON document with the `.bicep-test.json` extension that defines one or more test cases for your Bicep functions. Each test case specifies:
1. **Input** - The Bicep expression or function call to test
2. **Assertion** - What you expect the output to be (using one of 11 assertion types)
3. **Optional metadata** - Test name, description, and source file references

## File Location and Naming

- **Location**: Place test files in the `tests/` directory
- **Naming**: Use the `.bicep-test.json` extension (e.g., `concat.bicep-test.json`)
- **Organization**: Group related tests in subdirectories for clarity

Example structure:
```
tests/
├── string-functions/
│   ├── concat.bicep-test.json
│   ├── toLower.bicep-test.json
│   └── toUpper.bicep-test.json
├── math-functions/
│   ├── add.bicep-test.json
│   ├── multiply.bicep-test.json
│   └── divide.bicep-test.json
└── advanced/
    └── overlapping-subnets.bicep-test.json
```

## Two Test Formats

### Modern Format: Multiple Tests with Assertions (Recommended)

This format allows you to define multiple test cases in a single file with flexible assertion types.

```json
{
  "description": "Test suite for string functions",
  "tests": [
    {
      "name": "String concatenation",
      "input": "concat('hello', ' ', 'world')",
      "shouldBe": "'hello world'"
    },
    {
      "name": "Case transformation",
      "input": "toLower('HELLO')",
      "shouldContain": "hello"
    }
  ]
}
```

**Benefits**:
- Multiple tests in one file
- 11 different assertion types
- Clear test names
- Better organization

### Legacy Format: Single Test (Still Supported)

For backward compatibility, single-test format is still supported:

```json
{
  "description": "Test concat function with strings",
  "input": "concat('hello', ' ', 'world')",
  "expected": "'hello world'"
}
```

**Note**: New tests should use the modern format. Legacy tests will continue to work without modification.

## Test Case Structure

Each test case in the modern format has these properties:

### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `input` OR `bicepFile` + `functionCall` | string | Bicep expression to test |
| One assertion (e.g., `shouldBe`) | any | What you expect the output to be |

### Optional Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | string | Human-readable test name (shown in output) |
| `description` | string | Detailed description (only on root object) |
| `bicepFile` | string | Path to .bicep file with custom functions |
| `functionCall` | string | Function call when using bicepFile |

## Inline Tests vs. File References

### Inline Test (Direct Expression)

```json
{
  "name": "Test built-in concat",
  "input": "concat('a', 'b')",
  "shouldBe": "'ab'"
}
```

Use this for built-in Bicep functions.

### File Reference (Custom Functions)

```json
{
  "name": "Test custom add function",
  "bicepFile": "bicep-functions/math-functions.bicep",
  "functionCall": "add(5, 3)",
  "shouldBe": "8"
}
```

Use this when testing functions defined in a `.bicep` file. See [Loading Bicep Functions](./bicep-functions.md) for more details.

## Example: Complete Test File

```json
{
  "description": "Comprehensive string and math function tests",
  "tests": [
    {
      "name": "Concatenate multiple strings",
      "input": "concat('Hello', ' ', 'World', '!')",
      "shouldBe": "'Hello World!'"
    },
    {
      "name": "Case conversion to lowercase",
      "input": "toLower('HELLO')",
      "shouldBe": "'hello'"
    },
    {
      "name": "Case conversion to uppercase",
      "input": "toUpper('hello')",
      "shouldBe": "'HELLO'"
    },
    {
      "name": "String length",
      "input": "length('hello')",
      "shouldBe": "5"
    },
    {
      "name": "Array with numbers",
      "input": "length([1, 2, 3, 4, 5])",
      "shouldBe": "5"
    },
    {
      "name": "Custom function from bicep file",
      "bicepFile": "bicep-functions/math-functions.bicep",
      "functionCall": "add(10, 20)",
      "shouldBe": "30"
    }
  ]
}
```

## Running Tests

See [Script Parameters](./script-parameters.md) for how to run tests with various options.

**Basic run**:
```powershell
# Windows
.\run-tests.ps1

# Linux/macOS
./run-tests.sh
```

**Verbose output**:
```powershell
.\run-tests.ps1 -Verbose
```

**Parallel execution**:
```powershell
.\framework\run-tests.ps1 -Parallel
```

## Best Practices

1. **Use descriptive test names** - Make it clear what each test validates
2. **One assertion per test** - Keep tests focused and simple
3. **Group related tests** - Use subdirectories to organize test files
4. **Use file references for custom functions** - Keeps bicep code separate
5. **Test edge cases** - Include tests for empty inputs, boundary values, etc.

## Next Steps

- Learn about all [Assertion Types](./assertions.md)
- Explore the [Test File Format](./test-json-format.md) specification
- See how to [Load Bicep Functions](./bicep-functions.md)
