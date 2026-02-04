#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Bicep Function Unit Test Runner
    
.DESCRIPTION
    This script runs unit tests for Bicep functions using the bicep console feature.
    
.PARAMETER TestDir
    Directory containing test files (default: ./tests)
    
.PARAMETER VerboseOutput
    Enable verbose output
    
.PARAMETER Quiet
    Quiet mode - only show summary
    
.PARAMETER Parallel
    Run tests in parallel (default: uses number of CPU cores)
    
.PARAMETER MaxParallelJobs
    Maximum number of concurrent jobs when running in parallel
    
.EXAMPLE
    ./run-tests.ps1
    Run all tests in ./tests directory
    
.EXAMPLE
    ./run-tests.ps1 -TestDir ./my-tests
    Run tests from ./my-tests directory
    
.EXAMPLE
    ./run-tests.ps1 -VerboseOutput
    Run tests with verbose output

.EXAMPLE
    ./run-tests.ps1 -Parallel
    Run tests in parallel (default: uses number of CPU cores)

.EXAMPLE
    ./run-tests.ps1 -Parallel -MaxParallelJobs 4
    Run tests in parallel with maximum of 4 concurrent jobs
#>

param(
    [string]$TestDir = "./tests",
    [switch]$VerboseOutput,
    [switch]$Quiet,
    [switch]$Parallel,
    [int]$MaxParallelJobs = [Environment]::ProcessorCount
)

#region Helper Functions

function ConvertTo-NormalizedOutput {
    <#
    .SYNOPSIS
        Normalizes bicep console output for comparison
    #>
    param([string]$Output)
    
    $Output = $Output -replace "`r", ""
    
    $lines = $Output -split "`n" | Where-Object { 
        $_ -notmatch "WARNING: The 'console' CLI command is an experimental feature" -and
        $_ -notmatch "Experimental features should be used for testing purposes only" -and
        $_.Trim() -ne ""
    }
    
    return ($lines -join "`n").Trim()
}

function Get-AssertionConfig {
    <#
    .SYNOPSIS
        Returns assertion configuration for all supported assertion types
    #>
    return @{
        shouldBe = @{
            Evaluate = { param($actual, $expected) $actual -eq $expected }
            FormatFailure = { param($expected, $actual) "Expected: $expected`n    Actual:   $actual" }
        }
        shouldNotBe = @{
            Evaluate = { param($actual, $expected) $actual -ne $expected }
            FormatFailure = { param($expected, $actual) "Should NOT be: $expected`n    But actual was: $actual" }
        }
        shouldContain = @{
            Evaluate = { param($actual, $expected) $actual -like "*$expected*" }
            FormatFailure = { param($expected, $actual) "Should contain: $expected`n    Actual:         $actual" }
        }
        shouldNotContain = @{
            Evaluate = { param($actual, $expected) $actual -notlike "*$expected*" }
            FormatFailure = { param($expected, $actual) "Should NOT contain: $expected`n    But actual was:     $actual" }
        }
        shouldStartWith = @{
            Evaluate = { param($actual, $expected) $actual -like "$expected*" }
            FormatFailure = { param($expected, $actual) "Should start with: $expected`n    Actual:            $actual" }
        }
        shouldEndWith = @{
            Evaluate = { param($actual, $expected) $actual -like "*$expected" }
            FormatFailure = { param($expected, $actual) "Should end with: $expected`n    Actual:          $actual" }
        }
        shouldMatch = @{
            Evaluate = { param($actual, $expected) $actual -match $expected }
            FormatFailure = { param($expected, $actual) "Should match pattern: $expected`n    Actual:               $actual" }
            ValidateFirst = $true
        }
        shouldBeGreaterThan = @{
            Evaluate = { param($actual, $expected) [double]$actual -gt [double]$expected }
            FormatFailure = { param($expected, $actual) "Should be greater than: $expected`n    Actual:                 $actual" }
            NumericComparison = $true
        }
        shouldBeLessThan = @{
            Evaluate = { param($actual, $expected) [double]$actual -lt [double]$expected }
            FormatFailure = { param($expected, $actual) "Should be less than: $expected`n    Actual:              $actual" }
            NumericComparison = $true
        }
        shouldBeEmpty = @{
            Evaluate = { param($actual, $expected) $actual -eq "''" -or $actual -eq '""' -or $actual -eq "[]" -or $actual -eq "{}" -or $actual.Trim() -eq "" }
            FormatFailure = { param($expected, $actual) "Should be empty`n    But actual was: $actual" }
            NoExpectedValue = $true
        }
    }
}

function Invoke-Assertion {
    <#
    .SYNOPSIS
        Evaluates a single assertion and returns the result
    #>
    param(
        [string]$AssertionType,
        [string]$Actual,
        [string]$Expected,
        [hashtable]$AssertionConfig
    )
    
    $config = $AssertionConfig[$AssertionType]
    if (-not $config) {
        return @{
            Passed = $false
            Error = "Unknown assertion type: $AssertionType"
        }
    }
    
    $normalizedExpected = if ($config.NoExpectedValue) { $null } else { ConvertTo-NormalizedOutput $Expected }
    
    try {
        if ($config.ValidateFirst) {
            # Test regex validity first
            try { $null = "" -match $normalizedExpected } catch { 
                return @{ Passed = $false; Error = "Invalid regex pattern: $normalizedExpected" }
            }
        }
        
        if ($config.NumericComparison) {
            try { $null = [double]$Actual } catch {
                return @{ Passed = $false; Error = "Could not convert to numeric values for comparison`n    Actual: $Actual" }
            }
        }
        
        $passed = & $config.Evaluate $Actual $normalizedExpected
        $failureMessage = if (-not $passed) { & $config.FormatFailure $normalizedExpected $Actual } else { $null }
        
        return @{
            Passed = $passed
            FailureMessage = $failureMessage
            AssertionType = $AssertionType
            Expected = $normalizedExpected
        }
    }
    catch {
        return @{
            Passed = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-TestInput {
    <#
    .SYNOPSIS
        Resolves the input expression for a test (inline or from bicep file)
    #>
    param(
        [object]$Test
    )
    
    $bicepFile = $Test.bicepFile
    $functionCall = $Test.functionCall
    $inputExpr = $Test.input
    
    if ($bicepFile -and $functionCall) {
        if (-not (Test-Path $bicepFile)) {
            return @{ Success = $false; Error = "Bicep file not found: $bicepFile" }
        }
        
        $bicepContent = Get-Content $bicepFile -Raw
        $resolvedInput = "$bicepContent`n$functionCall"
        
        return @{
            Success = $true
            Input = $resolvedInput
            VerboseInfo = @{ BicepFile = $bicepFile; FunctionCall = $functionCall }
        }
    }
    elseif ($inputExpr) {
        return @{
            Success = $true
            Input = $inputExpr
            VerboseInfo = @{ Input = $inputExpr }
        }
    }
    else {
        return @{ Success = $false; Error = "Test must have either 'input' or 'bicepFile' + 'functionCall'" }
    }
}

function Find-AssertionInTest {
    <#
    .SYNOPSIS
        Finds the assertion type and value defined in a test
    #>
    param([object]$Test)
    
    $assertionTypes = @(
        'shouldBe', 'shouldNotBe', 'shouldContain', 'shouldNotContain',
        'shouldStartWith', 'shouldEndWith', 'shouldMatch',
        'shouldBeGreaterThan', 'shouldBeLessThan', 'shouldBeEmpty'
    )
    
    foreach ($type in $assertionTypes) {
        $value = $Test.$type
        if ($null -ne $value) {
            return @{ Type = $type; Value = $value }
        }
    }
    
    return $null
}

function Invoke-BicepConsole {
    <#
    .SYNOPSIS
        Executes bicep console and returns normalized output
    #>
    param([string]$BicepExpression)
    
    $rawOutput = $BicepExpression | bicep console 2>&1 | Out-String
    return ConvertTo-NormalizedOutput $rawOutput
}

function ConvertTo-TestResult {
    <#
    .SYNOPSIS
        Creates a standardized test result object
    #>
    param(
        [string]$TestName,
        [int]$TestIndex,
        [string]$DisplayName,
        [bool]$Passed,
        [string]$Error,
        [string]$FailureMessage,
        [string]$AssertionType,
        [string]$Actual
    )
    
    return @{
        TestName = $TestName
        TestIndex = $TestIndex
        DisplayName = $DisplayName
        Passed = $Passed
        Error = $ErrorMsg
        FailureMessage = $FailureMessage
        AssertionType = $AssertionType
        Actual = $Actual
    }
}

#endregion

#region Test Execution Functions

function Invoke-SingleTest {
    <#
    .SYNOPSIS
        Runs a single test case and returns the result
    #>
    param(
        [object]$Test,
        [string]$TestName,
        [int]$TestIndex,
        [bool]$ShowVerbose
    )
    
    $displayName = if ($Test.name) { $Test.name } else { "Test $TestIndex" }
    $assertionConfig = Get-AssertionConfig
    
    # Get test input
    $inputResult = Get-TestInput -Test $Test -ShowVerbose $ShowVerbose
    if (-not $inputResult.Success) {
        return ConvertTo-TestResult -TestName $TestName -TestIndex $TestIndex -DisplayName $displayName `
            -Passed $false -Error $inputResult.Error
    }
    
    # Find assertion
    $assertion = Find-AssertionInTest -Test $Test
    if (-not $assertion) {
        return ConvertTo-TestResult -TestName $TestName -TestIndex $TestIndex -DisplayName $displayName `
            -Passed $false -Error "Test must have one of: shouldBe, shouldNotBe, shouldContain, shouldNotContain, shouldStartWith, shouldEndWith, shouldMatch, shouldBeGreaterThan, shouldBeLessThan, shouldBeEmpty"
    }
    
    # Execute bicep console
    try {
        $actual = Invoke-BicepConsole -BicepExpression $inputResult.Input
    }
    catch {
        return ConvertTo-TestResult -TestName $TestName -TestIndex $TestIndex -DisplayName $displayName `
            -Passed $false -Error $_.Exception.Message
    }
    
    # Run assertion
    $assertionResult = Invoke-Assertion -AssertionType $assertion.Type -Actual $actual `
        -Expected $assertion.Value -AssertionConfig $assertionConfig
    
    if ($assertionResult.Error) {
        return ConvertTo-TestResult -TestName $TestName -TestIndex $TestIndex -DisplayName $displayName `
            -Passed $false -Error $assertionResult.Error -Actual $actual
    }
    
    return ConvertTo-TestResult -TestName $TestName -TestIndex $TestIndex -DisplayName $displayName `
        -Passed $assertionResult.Passed -FailureMessage $assertionResult.FailureMessage `
        -AssertionType $assertion.Type -Actual $actual
}

function ConvertTo-TestObject {
    <#
    .SYNOPSIS
        Converts legacy test format or raw test data to standardized test object
    #>
    param([object]$TestData)
    
    # If it's already a PSCustomObject from JSON, convert relevant properties
    $test = @{}
    
    # Handle input/bicepFile+functionCall
    if ($TestData.PSObject.Properties.Name -contains 'input' -and $TestData.input) {
        $test.input = $TestData.input
    }
    if ($TestData.PSObject.Properties.Name -contains 'bicepFile' -and $TestData.bicepFile) {
        $test.bicepFile = $TestData.bicepFile
    }
    if ($TestData.PSObject.Properties.Name -contains 'functionCall' -and $TestData.functionCall) {
        $test.functionCall = $TestData.functionCall
    }
    if ($TestData.PSObject.Properties.Name -contains 'name' -and $TestData.name) {
        $test.name = $TestData.name
    }
    
    # Handle assertions - check for 'expected' (legacy) or new assertion types
    if ($TestData.PSObject.Properties.Name -contains 'expected' -and $null -ne $TestData.expected) {
        $test.shouldBe = $TestData.expected
    }
    
    # Copy over all assertion types if present
    $assertionTypes = @('shouldBe', 'shouldNotBe', 'shouldContain', 'shouldNotContain',
        'shouldStartWith', 'shouldEndWith', 'shouldMatch', 'shouldBeGreaterThan', 
        'shouldBeLessThan', 'shouldBeEmpty')
    
    foreach ($assertionType in $assertionTypes) {
        if ($TestData.PSObject.Properties.Name -contains $assertionType -and $null -ne $TestData.$assertionType) {
            $test.$assertionType = $TestData.$assertionType
        }
    }
    
    return [PSCustomObject]$test
}

function Invoke-TestFile {
    <#
    .SYNOPSIS
        Runs all tests in a test file and returns results
    #>
    param(
        [string]$TestFile,
        [bool]$ShowVerbose
    )
    
    $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestFile) -replace '\.bicep-test$', ''
    $testData = Get-Content $TestFile -Raw | ConvertFrom-Json
    $results = @()
    
    # Determine test format and get tests
    $tests = if ($testData.PSObject.Properties.Name -contains 'tests') {
        # New format: multiple tests in array
        $testData.tests | ForEach-Object { ConvertTo-TestObject -TestData $_ }
    }
    else {
        # Legacy format - single test at root level
        @(ConvertTo-TestObject -TestData $testData)
    }
    
    if ($tests.Count -eq 0) {
        return @{
            TestName = $testName
            Description = $testData.description
            Results = @()
            Warning = "No tests defined in file"
        }
    }
    
    for ($i = 0; $i -lt $tests.Count; $i++) {
        $result = Invoke-SingleTest -Test $tests[$i] -TestName $testName -TestIndex ($i + 1) -ShowVerbose $ShowVerbose
        $results += $result
    }
    
    return @{
        TestName = $testName
        Description = $testData.description
        Results = $results
    }
}

#endregion

#region Output Functions

function Write-TestResult {
    <#
    .SYNOPSIS
        Writes a single test result to the console
    #>
    param(
        [object]$Result,
        [bool]$Quiet
    )
    
    if (-not $Quiet) {
        Write-Host "  [$($Result.TestIndex)] $($Result.DisplayName)" -ForegroundColor Cyan
    }
    
    if ($Result.Passed) {
        if (-not $Quiet) {
            Write-Host "    ✓ PASSED" -ForegroundColor Green
        }
    }
    else {
        Write-Host "    ✗ FAILED" -ForegroundColor Red
        if ($Result.Error) {
            Write-Host "    Error: $($Result.Error)" -ForegroundColor Red
        }
        elseif ($Result.FailureMessage) {
            $Result.FailureMessage -split "`n" | ForEach-Object { Write-Host "    $_" }
        }
    }
}

function Write-TestResult {
    <#
    .SYNOPSIS
        Writes all results for a test file to the console
    #>
    param(
        [object]$FileResult,
        [bool]$Quiet
    )
    
    if (-not $Quiet) {
        Write-Host "`nRunning test: $($FileResult.TestName)" -ForegroundColor Yellow
    }
    
    if ($FileResult.Description) {
        Write-Host "  Description: $($FileResult.Description)"
    }
    
    if ($FileResult.Warning) {
        Write-Host "  ✗ WARNING: $($FileResult.Warning)" -ForegroundColor Yellow
        return
    }
    
    foreach ($result in $FileResult.Results) {
        Write-SingleTestResult -Result $result -Quiet $Quiet
    }
}

function Write-SingleTestResult {
    <#
    .SYNOPSIS
        Writes a single test result to the console
    #>
    param(
        [object]$Result,
        [bool]$Quiet
    )
    
    if ($Quiet) { return }
    
    $testNum = $Result.TestIndex
    $testName = $Result.DisplayName
    
    Write-Host "    [$testNum] $testName"
    
    if ($Result.Passed) {
        Write-Host "      ✓ PASSED" -ForegroundColor Green
    }
    else {
        Write-Host "      ✗ FAILED" -ForegroundColor Red
        if ($Result.FailureMessage) {
            Write-Host "        $($Result.FailureMessage)" -ForegroundColor Red
        }
        if ($Result.Error) {
            Write-Host "        Error: $($Result.Error)" -ForegroundColor Red
        }
    }
}

function Write-TestSummary {
    <#
    .SYNOPSIS
        Writes the test summary to the console
    #>
    param(
        [int]$Total,
        [int]$Passed,
        [int]$Failed
    )
    
    Write-Host ""
    Write-Host "================================================"
    Write-Host "Test Summary"
    Write-Host "================================================"
    Write-Host "Total tests:  $Total"
    Write-Host "Passed:       $Passed" -ForegroundColor Green
    Write-Host "Failed:       $Failed" -ForegroundColor Red
    Write-Host "================================================"
}

#endregion

#region Main Execution

function Test-Prerequisite {
    <#
    .SYNOPSIS
        Validates that all prerequisites are met before running tests
    #>
    param(
        [string]$TestDirectory,
        [bool]$ShowVerbose
    )
    
    # Check if bicep is installed
    try {
        $bicepVersion = bicep --version 2>&1
        if ($ShowVerbose) {
            Write-Host "Bicep version: $bicepVersion"
        }
    }
    catch {
        Write-Host "Error: bicep CLI is not installed or not in PATH" -ForegroundColor Red
        return $false
    }
    
    # Check if test directory exists
    if (-not (Test-Path $TestDirectory)) {
        Write-Host "Error: Test directory '$TestDirectory' does not exist" -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Invoke-TestsSequential {
    <#
    .SYNOPSIS
        Runs all tests sequentially
    #>
    param(
        [array]$TestFiles,
        [bool]$ShowVerbose,
        [bool]$Quiet
    )
    
    $allResults = @()
    
    foreach ($testFile in $TestFiles) {
        $fileResult = Invoke-TestFile -TestFile $testFile.FullName -ShowVerbose $ShowVerbose
        Write-TestResult -FileResult $fileResult -Quiet $Quiet
        $allResults += $fileResult.Results
    }
    
    return $allResults
}

function Invoke-TestsParallel {
    <#
    .SYNOPSIS
        Runs all tests in parallel using ForEach-Object -Parallel
    #>
    param(
        [array]$TestFiles,
        [bool]$ShowVerbose,
        [bool]$Quiet,
        [int]$ThrottleLimit
    )
    
    # Export the script content for use in parallel runspaces
    $scriptPath = $PSScriptRoot
    
    $parallelResults = $TestFiles | ForEach-Object -Parallel {
        $testFile = $_
        $verboseMode = $using:ShowVerbose
        $scriptDir = $using:scriptPath
        
        # Re-import necessary functions in parallel scope
        # (PowerShell parallel runspaces don't share function definitions)
        
        function ConvertTo-NormalizedOutput {
            param([string]$Output)
            $Output = $Output -replace "`r", ""
            $lines = $Output -split "`n" | Where-Object { 
                $_ -notmatch "WARNING: The 'console' CLI command is an experimental feature" -and
                $_ -notmatch "Experimental features should be used for testing purposes only" -and
                $_.Trim() -ne ""
            }
            return ($lines -join "`n").Trim()
        }
        
        function Get-AssertionConfig {
            return @{
                shouldBe = @{
                    Evaluate = { param($actual, $expected) $actual -eq $expected }
                    FormatFailure = { param($expected, $actual) "Expected: $expected`n    Actual:   $actual" }
                }
                shouldNotBe = @{
                    Evaluate = { param($actual, $expected) $actual -ne $expected }
                    FormatFailure = { param($expected, $actual) "Should NOT be: $expected`n    But actual was: $actual" }
                }
                shouldContain = @{
                    Evaluate = { param($actual, $expected) $actual -like "*$expected*" }
                    FormatFailure = { param($expected, $actual) "Should contain: $expected`n    Actual:         $actual" }
                }
                shouldNotContain = @{
                    Evaluate = { param($actual, $expected) $actual -notlike "*$expected*" }
                    FormatFailure = { param($expected, $actual) "Should NOT contain: $expected`n    But actual was:     $actual" }
                }
                shouldStartWith = @{
                    Evaluate = { param($actual, $expected) $actual -like "$expected*" }
                    FormatFailure = { param($expected, $actual) "Should start with: $expected`n    Actual:            $actual" }
                }
                shouldEndWith = @{
                    Evaluate = { param($actual, $expected) $actual -like "*$expected" }
                    FormatFailure = { param($expected, $actual) "Should end with: $expected`n    Actual:          $actual" }
                }
                shouldMatch = @{
                    Evaluate = { param($actual, $expected) $actual -match $expected }
                    FormatFailure = { param($expected, $actual) "Should match pattern: $expected`n    Actual:               $actual" }
                    ValidateFirst = $true
                }
                shouldBeGreaterThan = @{
                    Evaluate = { param($actual, $expected) [double]$actual -gt [double]$expected }
                    FormatFailure = { param($expected, $actual) "Should be greater than: $expected`n    Actual:                 $actual" }
                    NumericComparison = $true
                }
                shouldBeLessThan = @{
                    Evaluate = { param($actual, $expected) [double]$actual -lt [double]$expected }
                    FormatFailure = { param($expected, $actual) "Should be less than: $expected`n    Actual:              $actual" }
                    NumericComparison = $true
                }
                shouldBeEmpty = @{
                    Evaluate = { param($actual, $expected) $actual -eq "''" -or $actual -eq '""' -or $actual -eq "[]" -or $actual -eq "{}" -or $actual.Trim() -eq "" }
                    FormatFailure = { param($expected, $actual) "Should be empty`n    But actual was: $actual" }
                    NoExpectedValue = $true
                }
            }
        }
        
        function Find-AssertionInTest {
            param([object]$Test)
            $assertionTypes = @('shouldBe', 'shouldNotBe', 'shouldContain', 'shouldNotContain',
                'shouldStartWith', 'shouldEndWith', 'shouldMatch', 'shouldBeGreaterThan', 
                'shouldBeLessThan', 'shouldBeEmpty')
            foreach ($type in $assertionTypes) {
                $value = $Test.$type
                if ($null -ne $value) { return @{ Type = $type; Value = $value } }
            }
            return $null
        }
        
        function Invoke-SingleTestParallel {
            param([object]$Test, [string]$TestName, [int]$TestIndex, [bool]$ShowVerbose)
            
            $displayName = if ($Test.name) { $Test.name } else { "Test $TestIndex" }
            $assertionConfig = Get-AssertionConfig
            
            # Get input
            $bicepFile = $Test.bicepFile
            $functionCall = $Test.functionCall
            $inputExpr = $Test.input
            
            if ($bicepFile -and $functionCall) {
                if (-not (Test-Path $bicepFile)) {
                    return @{ TestName = $TestName; TestIndex = $TestIndex; DisplayName = $displayName; Passed = $false; Error = "Bicep file not found: $bicepFile" }
                }
                $bicepContent = Get-Content $bicepFile -Raw
                $inputExpr = "$bicepContent`n$functionCall"
            }
            elseif (-not $inputExpr) {
                return @{ TestName = $TestName; TestIndex = $TestIndex; DisplayName = $displayName; Passed = $false; Error = "Test must have either 'input' or 'bicepFile' + 'functionCall'" }
            }
            
            # Find assertion
            $assertion = Find-AssertionInTest -Test $Test
            if (-not $assertion) {
                return @{ TestName = $TestName; TestIndex = $TestIndex; DisplayName = $displayName; Passed = $false; Error = "Test must have an assertion (shouldBe, shouldContain, etc.)" }
            }
            
            # Execute
            try {
                $rawOutput = $inputExpr | bicep console 2>&1 | Out-String
                $actual = ConvertTo-NormalizedOutput $rawOutput
            }
            catch {
                return @{ TestName = $TestName; TestIndex = $TestIndex; DisplayName = $displayName; Passed = $false; Error = $_.Exception.Message }
            }
            
            # Evaluate assertion
            $config = $assertionConfig[$assertion.Type]
            $normalizedExpected = if ($config.NoExpectedValue) { $null } else { ConvertTo-NormalizedOutput $assertion.Value }
            
            try {
                if ($config.ValidateFirst) {
                    try { $null = "" -match $normalizedExpected } catch { 
                        return @{ TestName = $TestName; TestIndex = $TestIndex; DisplayName = $displayName; Passed = $false; Error = "Invalid regex pattern: $normalizedExpected" }
                    }
                }
                if ($config.NumericComparison) {
                    try { $null = [double]$actual } catch {
                        return @{ TestName = $TestName; TestIndex = $TestIndex; DisplayName = $displayName; Passed = $false; Error = "Could not convert to numeric values`n    Actual: $actual" }
                    }
                }
                
                $passed = & $config.Evaluate $actual $normalizedExpected
                $failureMessage = if (-not $passed) { & $config.FormatFailure $normalizedExpected $actual } else { $null }
                
                return @{ TestName = $TestName; TestIndex = $TestIndex; DisplayName = $displayName; Passed = $passed; FailureMessage = $failureMessage; Actual = $actual }
            }
            catch {
                return @{ TestName = $TestName; TestIndex = $TestIndex; DisplayName = $displayName; Passed = $false; Error = $_.Exception.Message }
            }
        }
        
        # Process the test file
        $testName = [System.IO.Path]::GetFileNameWithoutExtension($testFile.FullName) -replace '\.bicep-test$', ''
        $testData = Get-Content $testFile.FullName -Raw | ConvertFrom-Json
        
        # Helper to convert test data to standardized format
        function ConvertTo-TestObjectParallel {
            param([object]$TestData)
            $test = @{}
            if ($TestData.PSObject.Properties.Name -contains 'input' -and $TestData.input) { $test.input = $TestData.input }
            if ($TestData.PSObject.Properties.Name -contains 'bicepFile' -and $TestData.bicepFile) { $test.bicepFile = $TestData.bicepFile }
            if ($TestData.PSObject.Properties.Name -contains 'functionCall' -and $TestData.functionCall) { $test.functionCall = $TestData.functionCall }
            if ($TestData.PSObject.Properties.Name -contains 'name' -and $TestData.name) { $test.name = $TestData.name }
            if ($TestData.PSObject.Properties.Name -contains 'expected' -and $null -ne $TestData.expected) { $test.shouldBe = $TestData.expected }
            $assertionTypes = @('shouldBe', 'shouldNotBe', 'shouldContain', 'shouldNotContain', 'shouldStartWith', 'shouldEndWith', 'shouldMatch', 'shouldBeGreaterThan', 'shouldBeLessThan', 'shouldBeEmpty')
            foreach ($at in $assertionTypes) {
                if ($TestData.PSObject.Properties.Name -contains $at -and $null -ne $TestData.$at) { $test.$at = $TestData.$at }
            }
            return [PSCustomObject]$test
        }
        
        $tests = if ($testData.PSObject.Properties.Name -contains 'tests') {
            $testData.tests | ForEach-Object { ConvertTo-TestObjectParallel -TestData $_ }
        } else {
            @(ConvertTo-TestObjectParallel -TestData $testData)
        }
        
        $results = @()
        for ($i = 0; $i -lt $tests.Count; $i++) {
            $results += Invoke-SingleTestParallel -Test $tests[$i] -TestName $testName -TestIndex ($i + 1) -ShowVerbose $verboseMode
        }
        
        return @{
            TestName = $testName
            Description = $testData.description
            Results = $results
        }
    } -ThrottleLimit $ThrottleLimit
    
    # Output results and collect all test results
    $allResults = @()
    foreach ($fileResult in $parallelResults) {
        Write-TestResult -FileResult $fileResult -Quiet $Quiet
        $allResults += $fileResult.Results
    }
    
    return $allResults
}

# Script entry point
Write-Host "================================================"
Write-Host "Bicep Function Unit Test Runner"
Write-Host "================================================"
Write-Host "Test directory: $TestDir"
Write-Host "Mode: $(if ($Parallel) { "Parallel (max $MaxParallelJobs jobs)" } else { 'Sequential' })"
Write-Host ""

# Validate prerequisites
if (-not (Test-Prerequisite -TestDirectory $TestDir)) {
    exit 1
}

# Find all test files
$testFiles = Get-ChildItem -Path $TestDir -Filter "*.bicep-test.json" -Recurse | Sort-Object Name

if ($testFiles.Count -eq 0) {
    Write-Host "No test files found in $TestDir" -ForegroundColor Yellow
    Write-Host "Test files should be named *.bicep-test.json"
    exit 0
}

# Run tests
$allResults = if ($Parallel) {
    Invoke-TestsParallel -TestFiles $testFiles -ShowVerbose $VerboseOutput -Quiet $Quiet -ThrottleLimit $MaxParallelJobs
} else {
    Invoke-TestsSequential -TestFiles $testFiles -ShowVerbose $VerboseOutput -Quiet $Quiet
}

# Calculate summary
$totalTests = $allResults.Count
$passedTests = ($allResults | Where-Object { $_.Passed }).Count
$failedTests = $totalTests - $passedTests

# Print summary
Write-TestSummary -Total $totalTests -Passed $passedTests -Failed $failedTests

# Exit with appropriate code
if ($failedTests -gt 0) {
    Write-Error "$failedTests test(s) failed"
    $global:LASTEXITCODE = 1
    exit 1
}

$global:LASTEXITCODE = 0
exit 0

#endregion
