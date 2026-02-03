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
#>

param(
    [string]$TestDir = "./tests",
    [switch]$VerboseOutput,
    [switch]$Quiet
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
        else {
            Write-Host "    ✗ FAILED" -ForegroundColor Red
            Write-Host "    Error: Test must have one of: shouldBe, shouldNotBe, or shouldContain"
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

# Run all tests
foreach ($testFile in $testFiles) {
    Run-Test -TestFile $testFile.FullName
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
