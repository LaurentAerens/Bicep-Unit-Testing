# Best Practices for Bicep Unit Testing

General guidelines to consider as you develop your testing approach. These will evolve based on community usage and feedback.

## Organization

### Keep Tests Organized

Group related tests in single files with clear descriptions:

```json
{
  "description": "String manipulation function tests",
  "tests": [
    {
      "name": "Concatenate multiple strings",
      "input": "concat('a', 'b', 'c')",
      "shouldBe": "'abc'"
    }
  ]
}
```

### Use Descriptive Names

Test names should clearly indicate what's being tested:

```
✅ Good:
- string-concatenation.bicep-test.json
- resource-naming-conventions.bicep-test.json

❌ Avoid:
- test1.bicep-test.json
- foo.bicep-test.json
```

## Testing Approach

### Choose the Right Assertion

Pick the assertion that best matches what you're testing:

- `shouldBe` - Exact matches
- `shouldContain` - Partial matches
- `shouldMatch` - Pattern matching
- `shouldBeGreaterThan` / `shouldBeLessThan` - Numeric comparisons
- See [Assertion Types](./assertions.md) for all options

### Test Happy Path and Edge Cases

Include tests for normal behavior and boundary conditions:

```json
{
  "tests": [
    {
      "name": "Normal case",
      "input": "concat('hello', ' ', 'world')",
      "shouldBe": "'hello world'"
    },
    {
      "name": "Empty input",
      "input": "length([])",
      "shouldBe": "0"
    }
  ]
}
```

### Document Your Tests

Add descriptions to explain why you're testing something:

```json
{
  "description": "Verify resource names follow organizational naming standards",
  "tests": [...]
}
```

## Performance

Use parallel execution for faster test runs:

```powershell
.\run-tests.ps1 -Parallel
```

See [Script Parameters](./script-parameters.md) for all execution options.

## CI/CD

Integrate tests into your pipelines - see [CI/CD Integration](./cicd-integration.md) for examples.

## Share Your Patterns

As you build tests, consider sharing patterns and approaches with the community. Best practices will evolve based on real-world usage.

## See Also

- [Test Files Overview](./test-files.md) - How to structure test files
- [Assertion Types](./assertions.md) - Available assertion options
- [Bicep Functions](./bicep-functions.md) - Testing custom functions
