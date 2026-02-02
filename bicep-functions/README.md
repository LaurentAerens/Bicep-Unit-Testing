# Bicep Functions

This directory contains custom Bicep function definitions that can be referenced in test files.

## Why Use Bicep Files for Functions?

When testing custom Bicep functions, you can:
1. Define your functions once in a `.bicep` file
2. Reference them in multiple test cases
3. Keep function definitions separate from test definitions
4. Better organize complex function libraries

## Usage

### 1. Define Functions in a Bicep File

Create a `.bicep` file with your function definitions:

**math-functions.bicep:**
```bicep
func add(a int, b int) int => a + b
func multiply(a int, b int) int => a * b
func isEven(n int) bool => n % 2 == 0
```

### 2. Reference in Test Files

Create test files that reference the Bicep file:

**tests/my-add-test.bicep-test.json:**
```json
{
  "description": "Test custom add function",
  "bicepFile": "bicep-functions/math-functions.bicep",
  "functionCall": "add(5, 3)",
  "expected": "8"
}
```

## Example Function Libraries

### math-functions.bicep
Simple mathematical operations for testing function basics.

### example-functions.bicep
More complex examples including:
- Resource naming conventions
- Subnet CIDR calculations
- Tag generation
- Environment validation

## Best Practices

1. **One file per category**: Group related functions together
2. **Clear naming**: Use descriptive function names
3. **Type safety**: Always specify parameter and return types
4. **Documentation**: Add comments explaining function purpose
5. **Pure functions**: Keep functions side-effect free for reliable testing

## Testing Your Functions

To test a function before creating a test file:

```bash
# Combine function definition with a call
cat bicep-functions/math-functions.bicep <(echo "add(5, 3)") | bicep console
```

Or use the test runner directly:

```bash
# Create a test file and run it
./run-tests.sh -v
```
