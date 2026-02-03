# Contributing to Bicep Unit Testing Framework

Thank you for your interest in contributing to the test framework! This guide covers contributing to the framework itself (PowerShell test runner, helper scripts, and documentation).

**Note:** If you're just looking to add tests for your own Bicep functions, see the [Quick Start Guide](./docs/quick-start.md) instead.

## Development Setup

1. Fork the repository
2. Clone your fork locally
3. Open in VS Code or PowerShell ISE
4. Ensure you have:
   - PowerShell 7+ (pwsh)
   - Bicep CLI v0.40.2 or later
   - Git for version control

## Project Structure

The framework consists of:
- **PowerShell Scripts**: Main test runner and helper utilities
- **Documentation**: Guides and references in `docs/`
- **Example Tests**: Sample test files showing usage

## Contributing Areas

### PowerShell Test Runner

The core of the project is the test runner script. Improvements welcome for:
- Performance optimization
- Error handling and messages
- New assertion types
- Parallel execution improvements
- Exit code handling

When modifying the runner:
1. Test thoroughly with existing test suite
2. Ensure backward compatibility with JSON format
3. Update documentation if behavior changes
4. Follow PowerShell best practices

### Helper Utilities

- `get-expected-output.ps1` - Formats bicep console output
- Other helper scripts improving the testing experience

### Documentation

- Guides in `docs/` folder
- README and quick-start guides
- Examples and use cases
- CI/CD integration examples

See [docs/index.md](./docs/index.md) for structure.

## Code Standards

### PowerShell Scripts
- Use `Set-StrictMode -Version Latest` for safety
- Include comment-based help documentation
- Use approved verbs (Get-, Test-, etc.)
- Follow [PowerShell naming conventions](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-powershell-commands)
- Handle errors gracefully with proper exit codes

### Documentation
- Keep guides focused on one topic
- Use clear, concise language
- Include practical examples
- Link to related documentation
- Use code blocks for commands and output

## Testing Changes

Before submitting a PR:

1. **Run the full test suite:**
   ```powershell
   .\run-tests.ps1 -Parallel
   ```

2. **Test with various scenarios:**
   ```powershell
   # Verbose output
   .\run-tests.ps1 -Verbose
   
   # Quiet mode
   .\run-tests.ps1 -Quiet
   
   # With custom test directory
   .\run-tests.ps1 -TestDir ./tests
   ```

3. **Verify exit codes:**
   ```powershell
   .\run-tests.ps1
   if ($LASTEXITCODE -eq 0) { Write-Host "Pass" } else { Write-Host "Fail: $LASTEXITCODE" }
   ```

## Submission Process

1. Create a feature branch from `main`
2. Make focused, well-documented changes
3. Test thoroughly
4. Submit a pull request with:
   - Clear description of changes
   - Why the change is needed
   - How you tested it
   - Any breaking changes (note these clearly)

## Code Review

PRs are reviewed for:
- Code quality and standards
- Backward compatibility
- Test coverage
- Documentation updates
- PowerShell best practices

## Questions?

- Check existing [documentation](./docs/)
- Review the PowerShell script for implementation details
- Open an issue to discuss ideas before starting major work

## License

By contributing, you agree that your contributions will be licensed under the  GNU GPL v3 License.
