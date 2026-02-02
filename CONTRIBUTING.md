# Contributing to Bicep Function Unit Testing

Thank you for your interest in contributing! This guide will help you add new tests and improve the framework.

## Adding New Tests

### Quick Steps

1. **Create a test file** in the `tests` directory with the `.bicep-test.json` extension
2. **Define your test** with input and expected output
3. **Run tests locally** to verify
4. **Submit a pull request**

### Test File Format

```json
{
  "description": "Clear description of what you're testing",
  "input": "The Bicep expression to evaluate",
  "expected": "The expected output from bicep console"
}
```

### Using Helper Scripts

To get the correct expected output, use the helper script:

**Linux/macOS:**
```bash
./get-expected-output.sh "your-bicep-expression"
```

**Windows:**
```powershell
.\get-expected-output.ps1 "your-bicep-expression"
```

This will show you exactly what to put in the `expected` field.

### Example Workflow

1. **Test your expression manually:**
   ```bash
   echo "length([1, 2, 3])" | bicep console
   ```

2. **Get the formatted output:**
   ```bash
   ./get-expected-output.sh "length([1, 2, 3])"
   ```

3. **Create your test file** (`tests/my-test.bicep-test.json`):
   ```json
   {
     "description": "Test length of array with 3 elements",
     "input": "length([1, 2, 3])",
     "expected": "3"
   }
   ```

4. **Run the tests:**
   ```bash
   ./run-tests.sh
   ```

## Test Categories

Consider adding tests for:

### String Functions
- `concat()`, `contains()`, `startsWith()`, `endsWith()`
- `toLower()`, `toUpper()`, `trim()`
- `replace()`, `substring()`, `split()`, `join()`

### Array Functions
- `length()`, `concat()`, `contains()`, `indexOf()`
- `first()`, `last()`, `skip()`, `take()`
- `union()`, `intersection()`, `difference()`

### Object Functions
- `contains()`, `length()`, `json()`
- `union()`, `intersection()`

### Network Functions
- `parseCidr()`, `cidrSubnet()`, `cidrHost()`

### Utility Functions
- `uniqueString()`, `guid()`, `base64()`
- `uri()`, `uriComponent()`

### Edge Cases
- Empty arrays: `length([])`
- Empty strings: `length('')`
- Null values and error conditions
- Boundary conditions

## Best Practices

1. **One test per file**: Keep tests focused and isolated
2. **Descriptive names**: Use clear file names like `concat-arrays.bicep-test.json`
3. **Good descriptions**: Explain what the test validates
4. **Test edge cases**: Include boundary conditions and error cases
5. **Keep it simple**: Test one thing at a time

## Testing Your Changes

Before submitting a PR, ensure:

1. **All tests pass locally:**
   ```bash
   ./run-tests.sh
   ```

2. **Tests work on both platforms** (if possible):
   ```bash
   ./run-tests.sh    # Bash
   pwsh ./run-tests.ps1  # PowerShell
   ```

3. **New tests are properly formatted** (valid JSON)

4. **Tests are deterministic** (same input always produces same output)

## Improving the Framework

We welcome improvements to:
- Test runner scripts (bash/PowerShell)
- GitHub Actions workflow
- Documentation
- Helper utilities
- Error handling and reporting

### Development Setup

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Code Style

### Bash Scripts
- Use shellcheck for linting
- Follow existing code style
- Add comments for complex logic

### PowerShell Scripts
- Follow PowerShell best practices
- Use approved verbs
- Include help documentation

### JSON Test Files
- Use 2-space indentation
- Validate JSON syntax
- Keep formatting consistent

## Questions?

If you have questions or need help:
1. Check the [README.md](README.md) for documentation
2. Look at existing tests for examples
3. Open an issue for discussion

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
