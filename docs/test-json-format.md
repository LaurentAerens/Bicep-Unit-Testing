# Test File Format Specification

Complete technical specification of the `.bicep-test.json` test file format.

## File Structure Overview

Test files follow either the modern multi-test format or legacy single-test format.

## Modern Format: Multiple Tests

The recommended format for new tests.

```json
{
  "description": "Optional description of the test suite",
  "tests": [
    {
      "name": "Optional test case name",
      "input": "bicep expression",
      "shouldBe": "expected value"
    },
    {
      "name": "Test with custom function",
      "bicepFile": "path/to/functions.bicep",
      "functionCall": "myFunction(param)",
      "shouldContain": "partial match"
    }
  ]
}
```

### Root Level Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `description` | string | No | Describes the test suite |
| `tests` | array | Yes | Array of test objects |

### Test Object Properties

#### Input Specification (choose one)

**Option 1: Inline Input**
| Property | Type | Description |
|----------|------|-------------|
| `input` | string | Bicep expression to evaluate directly |

Example:
```json
{
  "input": "concat('hello', 'world')"
}
```

**Option 2: Bicep File Reference**
| Property | Type | Description |
|----------|------|-------------|
| `bicepFile` | string | Path to .bicep file with function definitions |
| `functionCall` | string | Function call expression to evaluate |

Example:
```json
{
  "bicepFile": "bicep-functions/math-functions.bicep",
  "functionCall": "add(5, 3)"
}
```

#### Metadata (optional)

| Property | Type | Description |
|----------|------|-------------|
| `name` | string | Human-readable test name for reporting |
| `description` | string | Additional description (optional) |

#### Assertions (choose exactly one)

| Property | Type | Description |
|----------|------|-------------|
| `shouldBe` | any | Exact match assertion |
| `shouldNotBe` | any | Negation assertion |
| `shouldContain` | string | Substring assertion |
| `shouldNotContain` | string | Inverse substring assertion |
| `shouldStartWith` | string | Prefix assertion |
| `shouldEndWith` | string | Suffix assertion |
| `shouldMatch` | string | Regex pattern assertion |
| `shouldBeGreaterThan` | string/number | Greater than numeric assertion |
| `shouldBeLessThan` | string/number | Less than numeric assertion |
| `shouldBeGreaterThanOrEqual` | string/number | Greater than or equal numeric assertion |
| `shouldBeEmpty` | boolean | Empty check assertion |

**Important**: Each test must have exactly one assertion. Using multiple assertions in a single test is not supported.

## Legacy Format: Single Test

Still supported for backward compatibility.

```json
{
  "description": "Test concat function",
  "input": "concat('a', 'b')",
  "expected": "'ab'"
}
```

### Root Level Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `description` | string | Yes | Describes what is being tested |
| `input` | string | Yes* | Bicep expression to evaluate |
| `bicepFile` | string | Yes* | Path to .bicep file |
| `functionCall` | string | Yes* | Function call expression |
| `expected` | any | Yes | Expected output (exact match) |

*Use either `input` OR (`bicepFile` + `functionCall`)

## Complete Examples

### Example 1: Multi-test with inline inputs

```json
{
  "description": "Test string manipulation functions",
  "tests": [
    {
      "name": "Concatenate strings",
      "input": "concat('hello', ' ', 'world')",
      "shouldBe": "'hello world'"
    },
    {
      "name": "Uppercase transformation",
      "input": "toUpper('hello')",
      "shouldBe": "'HELLO'"
    },
    {
      "name": "Contains word check",
      "input": "toLower('HELLO')",
      "shouldContain": "hello"
    },
    {
      "name": "String length",
      "input": "length('test')",
      "shouldBe": "4"
    }
  ]
}
```

### Example 2: Custom functions from bicep file

```json
{
  "description": "Test custom mathematical functions",
  "tests": [
    {
      "name": "Add two numbers",
      "bicepFile": "bicep-functions/math-functions.bicep",
      "functionCall": "add(5, 3)",
      "shouldBe": "8"
    },
    {
      "name": "Multiply two numbers",
      "bicepFile": "bicep-functions/math-functions.bicep",
      "functionCall": "multiply(4, 5)",
      "shouldBe": "20"
    },
    {
      "name": "Check if number is even",
      "bicepFile": "bicep-functions/math-functions.bicep",
      "functionCall": "isEven(4)",
      "shouldBe": "true"
    }
  ]
}
```

### Example 3: Mixed inline and file references

```json
{
  "description": "Mixed test suite",
  "tests": [
    {
      "name": "Built-in function",
      "input": "length([1, 2, 3])",
      "shouldBe": "3"
    },
    {
      "name": "Custom function",
      "bicepFile": "bicep-functions/helpers.bicep",
      "functionCall": "formatName('myapp')",
      "shouldStartWith": "formatted-"
    },
    {
      "name": "Complex assertion",
      "input": "uniqueString(resourceGroup().id)",
      "shouldMatch": "^[a-z0-9]{13}$"
    }
  ]
}
```

### Example 4: Advanced assertions

```json
{
  "description": "Advanced assertion examples",
  "tests": [
    {
      "name": "Regex pattern matching for GUID",
      "input": "guid('seed')",
      "shouldMatch": "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
    },
    {
      "name": "Numeric comparison - greater than",
      "input": "length([1, 2, 3, 4, 5])",
      "shouldBeGreaterThan": "3"
    },
    {
      "name": "Numeric comparison - less than",
      "input": "100",
      "shouldBeLessThan": "200"
    },
    {
      "name": "Empty value check",
      "input": "empty()",
      "shouldBeEmpty": true
    },
    {
      "name": "No match assertion",
      "input": "concat('test', '123')",
      "shouldNotContain": "error"
    }
  ]
}
```

## Path Resolution

### Bicep File Paths

When using `bicepFile`, paths are resolved relative to the repository root:

```json
{
  "bicepFile": "bicep-functions/math-functions.bicep",
  "functionCall": "add(5, 3)"
}
```

This resolves to: `<repo-root>/bicep-functions/math-functions.bicep`

## Assertion Type Details

### String Assertions

**shouldBe** / **shouldNotBe**: For exact string matching
```json
{
  "shouldBe": "'exact value'"
}
```

**shouldContain** / **shouldNotContain**: For substring matching
```json
{
  "shouldContain": "substring"
}
```

**shouldStartWith** / **shouldEndWith**: For prefix/suffix matching
```json
{
  "shouldStartWith": "prefix",
  "shouldEndWith": ".json"
}
```

**shouldMatch**: For regex patterns
```json
{
  "shouldMatch": "^pattern.*$"
}
```

### Numeric Assertions

**shouldBeGreaterThan** / **shouldBeLessThan** / **shouldBeGreaterThanOrEqual**: Numeric comparisons
```json
{
  "shouldBeGreaterThan": "10",
  "shouldBeLessThan": "100",
  "shouldBeGreaterThanOrEqual": "0"
}
```

### Special Assertions

**shouldBeEmpty**: Checks for empty values
```json
{
  "shouldBeEmpty": true
}
```

## Common Patterns

### Testing Resource Naming

```json
{
  "name": "Resource name format validation",
  "input": "concat('rg-', resourceGroup().name)",
  "shouldMatch": "^rg-[a-z0-9-]+$"
}
```

### Testing Array Operations

```json
{
  "name": "Array length validation",
  "input": "length(split('a,b,c', ','))",
  "shouldBe": "3"
}
```

### Testing Conditional Logic

```json
{
  "name": "Environment validation",
  "bicepFile": "bicep-functions/validation.bicep",
  "functionCall": "isValidEnvironment('prod')",
  "shouldBe": "true"
}
```

## Validation Rules

1. **File naming**: Must end with `.bicep-test.json`
2. **JSON validity**: Must be valid JSON
3. **Required properties**: Either `input` OR (`bicepFile` + `functionCall`)
4. **Assertion requirement**: Exactly one assertion type must be present
5. **Expression validity**: Bicep expressions must be syntactically valid

## Backward Compatibility

The legacy single-test format will continue to work indefinitely:

```json
{
  "description": "Old format still works",
  "input": "concat('a', 'b')",
  "expected": "'ab'"
}
```

However, new test files should use the modern multi-test format with assertion types.

## See Also

- [Assertion Types Reference](./assertions.md) - Detailed explanation of each assertion
- [Test Files Overview](./test-files.md) - High-level test file concepts
- [Loading Bicep Functions](./bicep-functions.md) - How to use bicep files
