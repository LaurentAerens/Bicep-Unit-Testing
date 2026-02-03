#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Bicep Function Unit Test Runner
    
.DESCRIPTION
    This script runs unit tests for Bicep functions using the bicep console feature.
    
.PARAMETER TestDir
    Directory containing test files (default: ./tests)
    
.PARAMETER Verbose
    Enable verbose output
    
.PARAMETER Quiet
    Quiet mode - only show summary
    
.EXAMPLE
    ./run-tests.ps1
    Run all tests in ./tests directory
    
.EXAMPLE
    ./run-tests.ps1 -TestDir ./my-tests
    Run tests from ./my-tests directory
    
.EXAMPLE
    ./run-tests.ps1 -Verbose
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

# Counters
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

# Function to normalize output for comparison
function Normalize-Output {
    param([string]$Output)
    
    # Normalize line endings to Unix style (LF) by removing all CR characters
    $Output = $Output -replace "`r", ""
    
    # Remove the WARNING line about experimental feature and empty lines
    $lines = $Output -split "`n" | Where-Object { 
        $_ -notmatch "WARNING: The 'console' CLI command is an experimental feature" -and
        $_ -notmatch "Experimental features should be used for testing purposes only" -and
        $_.Trim() -ne ""
    }
    
    return ($lines -join "`n").Trim()
}

# Function to run a single test case
function Run-SingleTest {
    param(
        [object]$Test,
        [string]$TestName,
        [int]$TestIndex
    )
    
    $inputExpr = $Test.input
    $bicepFile = $Test.bicepFile
    $functionCall = $Test.functionCall
    $shouldBe = $Test.shouldBe
    $shouldNotBe = $Test.shouldNotBe
    $shouldContain = $Test.shouldContain
    $shouldNotContain = $Test.shouldNotContain
    $shouldStartWith = $Test.shouldStartWith
    $shouldEndWith = $Test.shouldEndWith
    $shouldMatch = $Test.shouldMatch
    $shouldBeGreaterThan = $Test.shouldBeGreaterThan
    $shouldBeLessThan = $Test.shouldBeLessThan
    $shouldBeEmpty = $Test.shouldBeEmpty
    $testDisplayName = if ($Test.name) { $Test.name } else { "Test $TestIndex" }
    
    if (-not $Quiet) {
        Write-Host "  [$TestIndex] $testDisplayName" -ForegroundColor Cyan
    }
    
    # Determine input based on test format
    if ($bicepFile -and $functionCall) {
        # Using bicepFile + functionCall format
        if (-not (Test-Path $bicepFile)) {
            Write-Host "    ✗ FAILED" -ForegroundColor Red
            Write-Host "    Error: Bicep file not found: $bicepFile"
            $script:FailedTests++
            return $false
        }
        
        # Extract function definitions from the bicep file
        $bicepContent = Get-Content $bicepFile -Raw
        
        # Combine function definitions with function call
        $inputExpr = @"
$bicepContent
$functionCall
"@
        
        if ($VerboseOutput) {
            Write-Host "    Bicep file: $bicepFile"
            Write-Host "    Function call: $functionCall"
        }
    } else {
        # Using inline input format
        if (-not $inputExpr) {
            Write-Host "    ✗ FAILED" -ForegroundColor Red
            Write-Host "    Error: Test must have either 'input' or 'bicepFile' + 'functionCall'"
            $script:FailedTests++
            return $false
        }
        
        if ($VerboseOutput) {
            Write-Host "    Input: $inputExpr"
        }
    }
    
    # Run bicep console
    try {
        $actualOutput = $inputExpr | bicep console 2>&1 | Out-String
        $actual = Normalize-Output $actualOutput
        
        if ($VerboseOutput) {
            Write-Host "    Actual: $actual"
        }
        
        # Determine which assertion to use
        $passed = $false
        $assertionType = ""
        $assertionValue = ""
        
        if ($null -ne $shouldBe) {
            # shouldBe: exact match
            $assertionType = "shouldBe"
            $expectedNormalized = Normalize-Output $shouldBe
            $assertionValue = $expectedNormalized
            $passed = ($actual -eq $expectedNormalized)
        }
        elseif ($null -ne $shouldNotBe) {
            # shouldNotBe: must not match
            $assertionType = "shouldNotBe"
            $notExpectedNormalized = Normalize-Output $shouldNotBe
            $assertionValue = $notExpectedNormalized
            $passed = ($actual -ne $notExpectedNormalized)
        }
        elseif ($null -ne $shouldContain) {
            # shouldContain: substring match
            $assertionType = "shouldContain"
            $containsNormalized = Normalize-Output $shouldContain
            $assertionValue = $containsNormalized
            $passed = ($actual -like "*$containsNormalized*")
        }
        elseif ($null -ne $shouldNotContain) {
            # shouldNotContain: must not contain substring
            $assertionType = "shouldNotContain"
            $notContainsNormalized = Normalize-Output $shouldNotContain
            $assertionValue = $notContainsNormalized
            $passed = ($actual -notlike "*$notContainsNormalized*")
        }
        elseif ($null -ne $shouldStartWith) {
            # shouldStartWith: starts with value
            $assertionType = "shouldStartWith"
            $startsWithNormalized = Normalize-Output $shouldStartWith
            $assertionValue = $startsWithNormalized
            $passed = ($actual -like "$startsWithNormalized*")
        }
        elseif ($null -ne $shouldEndWith) {
            # shouldEndWith: ends with value
            $assertionType = "shouldEndWith"
            $endsWithNormalized = Normalize-Output $shouldEndWith
            $assertionValue = $endsWithNormalized
            $passed = ($actual -like "*$endsWithNormalized")
        }
        elseif ($null -ne $shouldMatch) {
            # shouldMatch: regex pattern match
            $assertionType = "shouldMatch"
            $patternNormalized = Normalize-Output $shouldMatch
            $assertionValue = $patternNormalized
            try {
                $passed = ($actual -match $patternNormalized)
            }
            catch {
                Write-Host "    ✗ FAILED (Invalid Regex)" -ForegroundColor Red
                Write-Host "    Error: Invalid regex pattern: $patternNormalized"
                $script:FailedTests++
                return $false
            }
        }
        elseif ($null -ne $shouldBeGreaterThan) {
            # shouldBeGreaterThan: numeric comparison
            $assertionType = "shouldBeGreaterThan"
            $assertionValue = $shouldBeGreaterThan
            try {
                $actualNumeric = [double]$actual
                $expectedNumeric = [double]$shouldBeGreaterThan
                $passed = ($actualNumeric -gt $expectedNumeric)
            }
            catch {
                Write-Host "    ✗ FAILED (Not Numeric)" -ForegroundColor Red
                Write-Host "    Error: Could not convert to numeric values for comparison"
                Write-Host "    Actual: $actual"
                $script:FailedTests++
                return $false
            }
        }
        elseif ($null -ne $shouldBeLessThan) {
            # shouldBeLessThan: numeric comparison
            $assertionType = "shouldBeLessThan"
            $assertionValue = $shouldBeLessThan
            try {
                $actualNumeric = [double]$actual
                $expectedNumeric = [double]$shouldBeLessThan
                $passed = ($actualNumeric -lt $expectedNumeric)
            }
            catch {
                Write-Host "    ✗ FAILED (Not Numeric)" -ForegroundColor Red
                Write-Host "    Error: Could not convert to numeric values for comparison"
                Write-Host "    Actual: $actual"
                $script:FailedTests++
                return $false
            }
        }
        elseif ($null -ne $shouldBeEmpty) {
            # shouldBeEmpty: check if result is empty
            $assertionType = "shouldBeEmpty"
            $assertionValue = "true"
            $passed = ($actual -eq "''" -or $actual -eq '""' -or $actual -eq "[]" -or $actual -eq "{}" -or $actual.Trim() -eq "")
        }
        else {
            Write-Host "    ✗ FAILED" -ForegroundColor Red
            Write-Host "    Error: Test must have one of: shouldBe, shouldNotBe, shouldContain, shouldNotContain, shouldStartWith, shouldEndWith, shouldMatch, shouldBeGreaterThan, shouldBeLessThan, shouldBeEmpty"
            $script:FailedTests++
            return $false
        }
        
        # Report results
        if ($passed) {
            if (-not $Quiet) {
                Write-Host "    ✓ PASSED" -ForegroundColor Green
            }
            $script:PassedTests++
            return $true
        } else {
            Write-Host "    ✗ FAILED" -ForegroundColor Red
            switch ($assertionType) {
                "shouldBe" {
                    Write-Host "    Expected: $assertionValue"
                    Write-Host "    Actual:   $actual"
                }
                "shouldNotBe" {
                    Write-Host "    Should NOT be: $assertionValue"
                    Write-Host "    But actual was: $actual"
                }
                "shouldContain" {
                    Write-Host "    Should contain: $assertionValue"
                    Write-Host "    Actual:         $actual"
                }
                "shouldNotContain" {
                    Write-Host "    Should NOT contain: $assertionValue"
                    Write-Host "    But actual was:     $actual"
                }
                "shouldStartWith" {
                    Write-Host "    Should start with: $assertionValue"
                    Write-Host "    Actual:            $actual"
                }
                "shouldEndWith" {
                    Write-Host "    Should end with: $assertionValue"
                    Write-Host "    Actual:          $actual"
                }
                "shouldMatch" {
                    Write-Host "    Should match pattern: $assertionValue"
                    Write-Host "    Actual:               $actual"
                }
                "shouldBeGreaterThan" {
                    Write-Host "    Should be greater than: $assertionValue"
                    Write-Host "    Actual:                 $actual"
                }
                "shouldBeLessThan" {
                    Write-Host "    Should be less than: $assertionValue"
                    Write-Host "    Actual:              $actual"
                }
                "shouldBeEmpty" {
                    Write-Host "    Should be empty"
                    Write-Host "    But actual was: $actual"
                }
            }
            $script:FailedTests++
            return $false
        }
    }
    catch {
        Write-Host "    ✗ FAILED (Exception)" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
        $script:FailedTests++
        return $false
    }
}

# Function to run a test file (may contain multiple tests)
function Run-Test {
    param([string]$TestFile)
    
    $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestFile) -replace '\.bicep-test$', ''
    
    if (-not $Quiet) {
        Write-Host "`nRunning test: $testName" -ForegroundColor Yellow
    }
    
    # Read test file
    $testData = Get-Content $TestFile -Raw | ConvertFrom-Json
    $description = $testData.description
    
    if ($VerboseOutput -and $description) {
        Write-Host "  Description: $description"
    }
    
    # Check if this is the new multi-test format or legacy format
    if ($testData.PSObject.Properties.Name -contains 'tests') {
        # New format: multiple tests in array
        $tests = $testData.tests
        if ($tests.Count -eq 0) {
            Write-Host "  ✗ WARNING: No tests defined in file" -ForegroundColor Yellow
            return
        }
        
        for ($i = 0; $i -lt $tests.Count; $i++) {
            $script:TotalTests++
            Run-SingleTest -Test $tests[$i] -TestName $testName -TestIndex ($i + 1)
        }
    }
    else {
        # Legacy format: single test in root
        $script:TotalTests++
        
        # Convert legacy format to new format for processing
        $legacyTest = @{
            input = $testData.input
            bicepFile = $testData.bicepFile
            functionCall = $testData.functionCall
            shouldBe = $testData.expected  # Map 'expected' to 'shouldBe'
        }
        
        Run-SingleTest -Test $legacyTest -TestName $testName -TestIndex 1
    }
}

# Main execution
Write-Host "================================================"
Write-Host "Bicep Function Unit Test Runner"
Write-Host "================================================"
Write-Host "Test directory: $TestDir"
if ($Parallel) {
    Write-Host "Mode: Parallel (max $MaxParallelJobs jobs)"
} else {
    Write-Host "Mode: Sequential"
}
Write-Host ""

# Check if bicep is installed
try {
    $bicepVersion = bicep --version 2>&1
    if ($VerboseOutput) {
        Write-Host "Bicep version: $bicepVersion"
    }
}
catch {
    Write-Host "Error: bicep CLI is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if test directory exists
if (-not (Test-Path $TestDir)) {
    Write-Host "Error: Test directory '$TestDir' does not exist" -ForegroundColor Red
    exit 1
}

# Find all test files
$testFiles = Get-ChildItem -Path $TestDir -Filter "*.bicep-test.json" -Recurse | Sort-Object Name

if ($testFiles.Count -eq 0) {
    Write-Host "No test files found in $TestDir" -ForegroundColor Yellow
    Write-Host "Test files should be named *.bicep-test.json"
    exit 0
}

# Run tests (sequential or parallel)
if ($Parallel) {
    # Parallel execution with output buffering
    $testResults = @()
    
    $testFiles | ForEach-Object -Parallel {
        # Import functions and parameters into parallel scope
        $testFile = $_
        $VerboseOutput = $using:VerboseOutput
        $Quiet = $using:Quiet
        $TestDir = $using:TestDir
        
        # Output buffer for this test file
        $outputBuffer = @()
        
        # Re-define functions in parallel scope
        function Add-OutputLine {
            param([string]$Line, [string]$Color = "White")
            $global:outputBuffer += @{
                text = $Line
                color = $Color
            }
        }
        
        function Normalize-Output {
            param([string]$Output)
            $Output = $Output -replace "`r", ""
            $lines = $Output -split "`n" | Where-Object { 
                $_ -notmatch "WARNING: The 'console' CLI command is an experimental feature" -and
                $_ -notmatch "Experimental features should be used for testing purposes only" -and
                $_.Trim() -ne ""
            }
            return ($lines -join "`n").Trim()
        }
        
        function Run-SingleTest {
            param(
                [object]$Test,
                [string]$TestName,
                [int]$TestIndex
            )
            
            $inputExpr = $Test.input
            $bicepFile = $Test.bicepFile
            $functionCall = $Test.functionCall
            $shouldBe = $Test.shouldBe
            $shouldNotBe = $Test.shouldNotBe
            $shouldContain = $Test.shouldContain
            $shouldNotContain = $Test.shouldNotContain
            $shouldStartWith = $Test.shouldStartWith
            $shouldEndWith = $Test.shouldEndWith
            $shouldMatch = $Test.shouldMatch
            $shouldBeGreaterThan = $Test.shouldBeGreaterThan
            $shouldBeLessThan = $Test.shouldBeLessThan
            $shouldBeEmpty = $Test.shouldBeEmpty
            $testDisplayName = if ($Test.name) { $Test.name } else { "Test $TestIndex" }
            
            if (-not $Quiet) {
                Add-OutputLine "  [$TestIndex] $testDisplayName" "Cyan"
            }
            
            # Determine input based on test format
            if ($bicepFile -and $functionCall) {
                if (-not (Test-Path $bicepFile)) {
                    Add-OutputLine "    ✗ FAILED" "Red"
                    Add-OutputLine "    Error: Bicep file not found: $bicepFile" "Red"
                    return @{
                        passed = $false
                        testName = $testName
                        testIndex = $TestIndex
                        testDisplayName = $testDisplayName
                    }
                }
                
                $bicepContent = Get-Content $bicepFile -Raw
                
                $inputExpr = @"
$bicepContent
$functionCall
"@
                
                if ($VerboseOutput) {
                    Add-OutputLine "    Bicep file: $bicepFile" "White"
                    Add-OutputLine "    Function call: $functionCall" "White"
                }
            } else {
                if (-not $inputExpr) {
                    Add-OutputLine "    ✗ FAILED" "Red"
                    Add-OutputLine "    Error: Test must have either 'input' or 'bicepFile' + 'functionCall'" "Red"
                    return @{
                        passed = $false
                        testName = $testName
                        testIndex = $TestIndex
                        testDisplayName = $testDisplayName
                    }
                }
                
                if ($VerboseOutput) {
                    Add-OutputLine "    Input: $inputExpr" "White"
                }
            }
            
            # Run bicep console
            try {
                $actualOutput = $inputExpr | bicep console 2>&1 | Out-String
                $actual = Normalize-Output $actualOutput
                
                if ($VerboseOutput) {
                    Add-OutputLine "    Actual: $actual" "White"
                }
                
                # Determine which assertion to use
                $passed = $false
                $assertionType = ""
                $assertionValue = ""
                $expected = ""
                
                if ($null -ne $shouldBe) {
                    $assertionType = "shouldBe"
                    $expectedNormalized = Normalize-Output $shouldBe
                    $assertionValue = $expectedNormalized
                    $expected = $expectedNormalized
                    $passed = ($actual -eq $expectedNormalized)
                }
                elseif ($null -ne $shouldNotBe) {
                    $assertionType = "shouldNotBe"
                    $notExpectedNormalized = Normalize-Output $shouldNotBe
                    $assertionValue = $notExpectedNormalized
                    $expected = $notExpectedNormalized
                    $passed = ($actual -ne $notExpectedNormalized)
                }
                elseif ($null -ne $shouldContain) {
                    $assertionType = "shouldContain"
                    $containsNormalized = Normalize-Output $shouldContain
                    $assertionValue = $containsNormalized
                    $expected = $containsNormalized
                    $passed = ($actual -like "*$containsNormalized*")
                }
                elseif ($null -ne $shouldNotContain) {
                    $assertionType = "shouldNotContain"
                    $notContainsNormalized = Normalize-Output $shouldNotContain
                    $assertionValue = $notContainsNormalized
                    $expected = $notContainsNormalized
                    $passed = ($actual -notlike "*$notContainsNormalized*")
                }
                elseif ($null -ne $shouldStartWith) {
                    $assertionType = "shouldStartWith"
                    $startsWithNormalized = Normalize-Output $shouldStartWith
                    $assertionValue = $startsWithNormalized
                    $expected = $startsWithNormalized
                    $passed = ($actual -like "$startsWithNormalized*")
                }
                elseif ($null -ne $shouldEndWith) {
                    $assertionType = "shouldEndWith"
                    $endsWithNormalized = Normalize-Output $shouldEndWith
                    $assertionValue = $endsWithNormalized
                    $expected = $endsWithNormalized
                    $passed = ($actual -like "*$endsWithNormalized")
                }
                elseif ($null -ne $shouldMatch) {
                    $assertionType = "shouldMatch"
                    $patternNormalized = Normalize-Output $shouldMatch
                    $assertionValue = $patternNormalized
                    $expected = $patternNormalized
                    try {
                        $passed = ($actual -match $patternNormalized)
                    }
                    catch {
                        Add-OutputLine "    ✗ FAILED (Invalid Regex)" "Red"
                        Add-OutputLine "    Error: Invalid regex pattern: $patternNormalized" "Red"
                        return @{
                            passed = $false
                            testName = $testName
                            testIndex = $TestIndex
                            testDisplayName = $testDisplayName
                        }
                    }
                }
                elseif ($null -ne $shouldBeGreaterThan) {
                    $assertionType = "shouldBeGreaterThan"
                    $assertionValue = $shouldBeGreaterThan
                    $expected = $shouldBeGreaterThan
                    try {
                        $actualNumeric = [double]$actual
                        $expectedNumeric = [double]$shouldBeGreaterThan
                        $passed = ($actualNumeric -gt $expectedNumeric)
                    }
                    catch {
                        Add-OutputLine "    ✗ FAILED (Not Numeric)" "Red"
                        Add-OutputLine "    Error: Could not convert to numeric values for comparison" "Red"
                        Add-OutputLine "    Actual: $actual" "Red"
                        return @{
                            passed = $false
                            testName = $testName
                            testIndex = $TestIndex
                            testDisplayName = $testDisplayName
                        }
                    }
                }
                elseif ($null -ne $shouldBeLessThan) {
                    $assertionType = "shouldBeLessThan"
                    $assertionValue = $shouldBeLessThan
                    $expected = $shouldBeLessThan
                    try {
                        $actualNumeric = [double]$actual
                        $expectedNumeric = [double]$shouldBeLessThan
                        $passed = ($actualNumeric -lt $expectedNumeric)
                    }
                    catch {
                        Add-OutputLine "    ✗ FAILED (Not Numeric)" "Red"
                        Add-OutputLine "    Error: Could not convert to numeric values for comparison" "Red"
                        Add-OutputLine "    Actual: $actual" "Red"
                        return @{
                            passed = $false
                            testName = $testName
                            testIndex = $TestIndex
                            testDisplayName = $testDisplayName
                        }
                    }
                }
                elseif ($null -ne $shouldBeEmpty) {
                    $assertionType = "shouldBeEmpty"
                    $assertionValue = "true"
                    $expected = "empty"
                    $passed = ($actual -eq "''" -or $actual -eq '""' -or $actual -eq "[]" -or $actual -eq "{}" -or $actual.Trim() -eq "")
                }
                else {
                    Add-OutputLine "    ✗ FAILED" "Red"
                    Add-OutputLine "    Error: Test must have one of: shouldBe, shouldNotBe, shouldContain, shouldNotContain, shouldStartWith, shouldEndWith, shouldMatch, shouldBeGreaterThan, shouldBeLessThan, shouldBeEmpty" "Red"
                    return @{
                        passed = $false
                        testName = $testName
                        testIndex = $TestIndex
                        testDisplayName = $testDisplayName
                    }
                }
                
                # Report results
                if ($passed) {
                    if (-not $Quiet) {
                        Add-OutputLine "    ✓ PASSED" "Green"
                    }
                    return @{
                        passed = $true
                        testName = $testName
                        testIndex = $TestIndex
                        testDisplayName = $testDisplayName
                    }
                } else {
                    Add-OutputLine "    ✗ FAILED" "Red"
                    switch ($assertionType) {
                        "shouldBe" {
                            Add-OutputLine "    Expected: $assertionValue" "Red"
                            Add-OutputLine "    Actual:   $actual" "Red"
                        }
                        "shouldNotBe" {
                            Add-OutputLine "    Should NOT be: $assertionValue" "Red"
                            Add-OutputLine "    But actual was: $actual" "Red"
                        }
                        "shouldContain" {
                            Add-OutputLine "    Should contain: $assertionValue" "Red"
                            Add-OutputLine "    Actual:         $actual" "Red"
                        }
                        "shouldNotContain" {
                            Add-OutputLine "    Should NOT contain: $assertionValue" "Red"
                            Add-OutputLine "    But actual was:     $actual" "Red"
                        }
                        "shouldStartWith" {
                            Add-OutputLine "    Should start with: $assertionValue" "Red"
                            Add-OutputLine "    Actual:            $actual" "Red"
                        }
                        "shouldEndWith" {
                            Add-OutputLine "    Should end with: $assertionValue" "Red"
                            Add-OutputLine "    Actual:          $actual" "Red"
                        }
                        "shouldMatch" {
                            Add-OutputLine "    Should match pattern: $assertionValue" "Red"
                            Add-OutputLine "    Actual:               $actual" "Red"
                        }
                        "shouldBeGreaterThan" {
                            Add-OutputLine "    Should be greater than: $assertionValue" "Red"
                            Add-OutputLine "    Actual:                 $actual" "Red"
                        }
                        "shouldBeLessThan" {
                            Add-OutputLine "    Should be less than: $assertionValue" "Red"
                            Add-OutputLine "    Actual:              $actual" "Red"
                        }
                        "shouldBeEmpty" {
                            Add-OutputLine "    Should be empty" "Red"
                            Add-OutputLine "    But actual was: $actual" "Red"
                        }
                    }
                    return @{
                        passed = $false
                        testName = $testName
                        testIndex = $TestIndex
                        testDisplayName = $testDisplayName
                    }
                }
            }
            catch {
                Add-OutputLine "    ✗ FAILED (Exception)" "Red"
                Add-OutputLine "    Error: $_" "Red"
                return @{
                    passed = $false
                    testName = $testName
                    testIndex = $TestIndex
                    testDisplayName = $testDisplayName
                }
            }
        }
        
        function Run-Test {
            param([string]$TestFile)
            
            $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestFile) -replace '\.bicep-test$', ''
            
            Add-OutputLine "`nRunning test: $testName" "Yellow"
            
            # Read test file
            $testData = Get-Content $TestFile -Raw | ConvertFrom-Json
            $description = $testData.description
            
            if ($VerboseOutput -and $description) {
                Add-OutputLine "  Description: $description" "White"
            }
            
            $results = @()
            
            # Check if this is the new multi-test format or legacy format
            if ($testData.PSObject.Properties.Name -contains 'tests') {
                # New format: multiple tests in array
                $tests = $testData.tests
                if ($tests.Count -eq 0) {
                    Add-OutputLine "  ✗ WARNING: No tests defined in file" "Yellow"
                    return $results
                }
                
                for ($i = 0; $i -lt $tests.Count; $i++) {
                    $result = Run-SingleTest -Test $tests[$i] -TestName $testName -TestIndex ($i + 1)
                    $results += $result
                }
            }
            else {
                # Legacy format: single test in root
                $legacyTest = @{
                    input = $testData.input
                    bicepFile = $testData.bicepFile
                    functionCall = $testData.functionCall
                    shouldBe = $testData.expected
                }
                
                $result = Run-SingleTest -Test $legacyTest -TestName $testName -TestIndex 1
                $results += $result
            }
            
            return $results
        }
        
        # Run the test file and return results with output buffer
        $testResults = Run-Test -TestFile $testFile.FullName
        
        # Return object with results and buffered output
        return @{
            testResults = $testResults
            output = $outputBuffer
        }
        
    } -ThrottleLimit $MaxParallelJobs | ForEach-Object {
        # Print buffered output for this test file
        foreach ($outputLine in $_.output) {
            Write-Host $outputLine.text -ForegroundColor $outputLine.color
        }
        
        # Aggregate test results
        foreach ($result in $_.testResults) {
            $testResults += $result
        }
    }
    
    # Aggregate results
    $script:TotalTests = $testResults.Count
    $script:PassedTests = ($testResults | Where-Object { $_.passed }).Count
    $script:FailedTests = ($testResults | Where-Object { -not $_.passed }).Count
    
} else {
    # Sequential execution (original behavior)
    foreach ($testFile in $testFiles) {
        Run-Test -TestFile $testFile.FullName
    }
}

# Print summary
Write-Host ""
Write-Host "================================================"
Write-Host "Test Summary"
Write-Host "================================================"
Write-Host "Total tests:  $script:TotalTests"
Write-Host "Passed:       $script:PassedTests" -ForegroundColor Green
Write-Host "Failed:       $script:FailedTests" -ForegroundColor Red
Write-Host "================================================"

# Exit with appropriate code
if ($script:FailedTests -gt 0) {
    Write-Error "$($script:FailedTests) test(s) failed"
    # Ensure process exit code is set for different hosting scenarios
    try {
        $global:LASTEXITCODE = 1
    }
    catch {
        # ignore if cannot set
    }
    exit 1
} else {
    try {
        $global:LASTEXITCODE = 0
    }
    catch {}
    exit 0
}
