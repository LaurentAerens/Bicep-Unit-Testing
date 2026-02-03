# Loading and Using Bicep Functions

Learn how to test your existing Bicep functions.

## Overview

If you have custom Bicep functions in your codebase, you can test them by referencing the `.bicep` files in your test definitions. The test runner will load the function definitions and evaluate your test cases against them.

## How It Works

When you reference a Bicep file in a test:

1. **You specify** the path to your `.bicep` file and the function call to test
2. **The test runner** reads the entire `.bicep` file content
3. **It combines** the function definitions with your function call
4. **It pipes** this combined input to `bicep console`
5. **It evaluates** the output against your assertion

This means you can test any Bicep function that exists in your repository.

## Referencing Your Functions in Tests

### Basic Syntax

Use two properties in your test JSON:
- `bicepFile`: Relative path to your `.bicep` file (from repo root)
- `functionCall`: The function call expression to test

```json
{
  "name": "Test my custom function",
  "bicepFile": "src/modules/helpers.bicep",
  "functionCall": "myFunction(param1, param2)",
  "shouldBe": "expected-result"
}
```

### How the Script Loads Functions

When the test runner encounters `bicepFile`:

```powershell
# 1. Script reads your entire bicep file
$bicepContent = Get-Content "src/modules/helpers.bicep" -Raw

# 2. Combines it with your function call
$combined = @"
$bicepContent
myFunction(param1, param2)
"@

# 3. Pipes to bicep console for evaluation
$result = $combined | bicep console
```

This means **all functions** defined in that `.bicep` file are available during the test.

### Path Resolution

Paths are relative to your repository root:

```json
{
  "bicepFile": "src/utils/math.bicep",          // Your utils folder
  "functionCall": "add(10, 20)"
}
```

```json
{
  "bicepFile": "modules/networking/cidr.bicep",  // Your modules
  "functionCall": "calculateSubnet('10.0.0.0/16')"
}
```

```json
{
  "bicepFile": "infra/functions/naming.bicep",   // Your infra code
  "functionCall": "getResourceName('myapp', 'prod')"
}
```

## Examples

See [Test Files Overview](./test-files.md) for complete test examples with custom Bicep functions.

## Troubleshooting

**Function not found**: Check the function name spelling and verify the bicep file path is correct.

**Type mismatch**: Ensure parameter types match your function definition.

**File not found**: Verify the path is relative to repository root and uses forward slashes.

## See Also

- [Test File Format](./test-json-format.md) - Detailed format specification
- [Test Files Overview](./test-files.md) - Testing concepts
- [Assertion Types](./assertions.md) - Validation options
