# New Assertion Types Added

## Summary

Added 7 new assertion types to the Bicep unit testing framework, bringing the total from 3 to 11 assertion types.

## New Assertions

### 1. **shouldNotContain**
- **Purpose**: Verify that output does NOT contain a specific substring
- **Use case**: Ensure certain text has been removed or is not present
- **Example**: Verify that "production" doesn't appear in a sanitized string

### 2. **shouldStartWith**
- **Purpose**: Check if output starts with a specific value
- **Use case**: Validate prefixes, file extensions, or initial patterns
- **Example**: Ensure a generated name starts with "bicep"

### 3. **shouldEndWith**
- **Purpose**: Check if output ends with a specific value
- **Use case**: Validate suffixes, file extensions, or ending patterns
- **Example**: Ensure a file path ends with ".json"

### 4. **shouldMatch**
- **Purpose**: Regex pattern matching
- **Use case**: Complex pattern validation like version strings, GUIDs, IP addresses
- **Example**: Validate that output matches a version pattern like "v1.2.3"

### 5. **shouldBeGreaterThan**
- **Purpose**: Numeric comparison (>)
- **Use case**: Validate array lengths, numeric calculations, size checks
- **Example**: Ensure array length is greater than 3

### 6. **shouldBeLessThan**
- **Purpose**: Numeric comparison (<)
- **Use case**: Validate limits, bounds checking, size constraints
- **Example**: Ensure result is less than a maximum value

### 7. **shouldBeEmpty**
- **Purpose**: Check for empty values (empty string, array, or object)
- **Use case**: Validate that operations result in empty collections or strings
- **Example**: Verify that a filter operation returns an empty array

## Files Modified

1. **framework/run-tests.ps1**
   - Added logic for all 7 new assertion types
   - Enhanced error reporting for each assertion
   - Added regex validation support
   - Added numeric conversion and comparison logic

2. **framework/test-template.json**
   - Updated documentation to include all 11 assertion types
   - Added detailed descriptions for each new assertion

3. **README.md**
   - Updated features list to mention 11 assertion types
   - Added comprehensive "Assertion Types Reference" section with examples
   - Updated all assertion type lists throughout the document

4. **tests/advanced-assertions.bicep-test.json** (NEW)
   - Created comprehensive test file with 18 test cases
   - Demonstrates all 11 assertion types
   - Includes practical examples and edge cases

## Test Results

All 18 tests in the new test file passed successfully:
- ✅ shouldBe examples
- ✅ shouldNotBe examples
- ✅ shouldContain examples
- ✅ shouldNotContain examples
- ✅ shouldStartWith examples
- ✅ shouldEndWith examples
- ✅ shouldMatch examples (regex patterns)
- ✅ shouldBeGreaterThan examples
- ✅ shouldBeLessThan examples
- ✅ shouldBeEmpty examples

## Benefits

These new assertions provide:
1. **More precise testing** - Target specific aspects of output
2. **Better validation** - Numeric comparisons and regex patterns
3. **Comprehensive coverage** - Test both positive and negative cases
4. **Clearer intent** - Each assertion type expresses what you're testing
5. **Less verbose tests** - No need for complex workarounds
6. **Better error messages** - Specific feedback for each assertion type

## Backward Compatibility

All existing tests continue to work without modification. The original 3 assertion types (shouldBe, shouldNotBe, shouldContain) remain fully functional.
