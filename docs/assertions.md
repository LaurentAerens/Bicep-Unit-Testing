# Assertion Types Reference

This document describes all 11 assertion types available in the Bicep unit testing framework.

## Quick Reference

| Assertion                    | Purpose            | Example                                  |
| ---------------------------- | ------------------ | ---------------------------------------- |
| `shouldBe`                   | Exact match        | `"shouldBe": "'hello world'"`            |
| `shouldNotBe`                | Not equal to       | `"shouldNotBe": "0"`                     |
| `shouldContain`              | Contains substring | `"shouldContain": "hello"`               |
| `shouldNotContain`           | Does not contain   | `"shouldNotContain": "error"`            |
| `shouldStartWith`            | Starts with text   | `"shouldStartWith": "bicep"`             |
| `shouldEndWith`              | Ends with text     | `"shouldEndWith": ".json"`               |
| `shouldMatch`                | Regex pattern      | `"shouldMatch": "^v\\d+\\.\\d+\\.\\d+$"` |
| `shouldBeGreaterThan`        | Numeric >          | `"shouldBeGreaterThan": "5"`             |
| `shouldBeLessThan`           | Numeric <          | `"shouldBeLessThan": "100"`              |
| `shouldBeEmpty`              | Empty check        | `"shouldBeEmpty": true`                  |
| `shouldBeGreaterThanOrEqual` | Numeric >=         | `"shouldBeGreaterThanOrEqual": "10"`     |

## Detailed Assertions

### shouldBe
**Purpose**: Verify that output exactly matches the expected value.

**Use when**: You need an exact match with no variations.

**Example**:
```json
{
  "name": "String concatenation",
  "input": "concat('hello', ' ', 'world')",
  "shouldBe": "'hello world'"
}
```

---

### shouldNotBe
**Purpose**: Verify that output does NOT equal a specific value.

**Use when**: You want to ensure a certain value was not produced.

**Example**:
```json
{
  "name": "Array length should not be zero",
  "input": "length([1, 2, 3])",
  "shouldNotBe": "0"
}
```

---

### shouldContain
**Purpose**: Verify that output contains a specific substring.

**Use when**: The exact output is hard to predict, but you know it contains something specific.

**Example**:
```json
{
  "name": "Output should contain 'success'",
  "input": "toLower('SUCCESS MESSAGE')",
  "shouldContain": "success"
}
```

---

### shouldNotContain
**Purpose**: Verify that output does NOT contain a specific substring.

**Use when**: You need to ensure certain text has been removed or sanitized.

**Example**:
```json
{
  "name": "Sanitized string should not contain password",
  "input": "replace('admin:password@host', ':password', '')",
  "shouldNotContain": "password"
}
```

---

### shouldStartWith
**Purpose**: Verify that output starts with a specific value.

**Use when**: You need to validate a prefix or initial pattern.

**Example**:
```json
{
  "name": "Resource name should start with prefix",
  "input": "concat('rg-', 'myapp')",
  "shouldStartWith": "rg-"
}
```

---

### shouldEndWith
**Purpose**: Verify that output ends with a specific value.

**Use when**: You need to validate a suffix or file extension.

**Example**:
```json
{
  "name": "File path should end with .json",
  "input": "concat('config', '.', 'json')",
  "shouldEndWith": ".json"
}
```

---

### shouldMatch
**Purpose**: Verify that output matches a regular expression pattern.

**Use when**: You need complex pattern validation (e.g., version strings, GUIDs, IP addresses).

**Examples**:

Version format:
```json
{
  "name": "Version should match semantic versioning",
  "input": "concat('v', '1.2.3')",
  "shouldMatch": "^v\\d+\\.\\d+\\.\\d+$"
}
```

UUID format:
```json
{
  "name": "Output should be a valid GUID",
  "input": "guid()",
  "shouldMatch": "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
}
```

IPv4 address:
```json
{
  "name": "Should be valid IPv4",
  "input": "cidrSubnet('192.168.0.0/24', 24, 0)",
  "shouldMatch": "^192\\.168\\.0\\.0/24$"
}
```

---

### shouldBeGreaterThan
**Purpose**: Verify that output is greater than a numeric value.

**Use when**: You need numeric comparisons for lengths, counts, or calculations.

**Example**:
```json
{
  "name": "Array length should be greater than 3",
  "input": "length([1, 2, 3, 4, 5])",
  "shouldBeGreaterThan": "3"
}
```

---

### shouldBeLessThan
**Purpose**: Verify that output is less than a numeric value.

**Use when**: You need to validate upper bounds or limits.

**Example**:
```json
{
  "name": "Cost should be less than budget",
  "input": "123",
  "shouldBeLessThan": "500"
}
```

---

### shouldBeGreaterThanOrEqual
**Purpose**: Verify that output is greater than or equal to a numeric value.

**Use when**: You need to validate minimum values or acceptable ranges.

**Example**:
```json
{
  "name": "Count should be at least 1",
  "input": "length([1])",
  "shouldBeGreaterThanOrEqual": "1"
}
```

---

### shouldBeEmpty
**Purpose**: Verify that output is empty (empty string, array, or object).

**Use when**: You need to confirm that an operation resulted in an empty collection or string.

**Example**:
```json
{
  "name": "Filter should return empty array",
  "input": "empty()",
  "shouldBeEmpty": true
}
```

Or with a property to check:
```json
{
  "name": "Result should be empty string",
  "input": "replace('hello', 'hello', '')",
  "shouldBeEmpty": true
}
```

---

## Combining Assertions

Each test can have **exactly one** assertion type. Choose the one that best matches what you're testing:

```json
{
  "tests": [
    {
      "name": "Exact value test",
      "input": "add(2, 3)",
      "shouldBe": "5"
    },
    {
      "name": "Prefix validation",
      "input": "concat('rg-', 'myapp')",
      "shouldStartWith": "rg-"
    },
    {
      "name": "Length validation",
      "input": "length([1, 2, 3, 4])",
      "shouldBeGreaterThan": "3"
    }
  ]
}
```

## Common Patterns

### Testing Mathematical Operations
```json
{
  "name": "Add function result",
  "input": "add(10, 5)",
  "shouldBeGreaterThan": "10"
}
```

### Testing String Transformations
```json
{
  "name": "Uppercase transformation",
  "input": "toUpper('hello')",
  "shouldContain": "HELLO"
}
```

### Testing Array Operations
```json
{
  "name": "Array filter result",
  "input": "filter([1, 2, 3], x => x > 5)",
  "shouldBeEmpty": true
}
```

### Testing Resource Naming
```json
{
  "name": "Resource name format",
  "input": "getResourceName('myapp', 'prod')",
  "shouldMatch": "^[a-z]([a-z0-9]{0,60}[a-z0-9])?$"
}
```
