#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Helper script to get expected output for a Bicep expression

.PARAMETER Expression
    The Bicep expression to evaluate

.EXAMPLE
    ./get-expected-output.ps1 "length([1, 2, 3])"

.EXAMPLE
    ./get-expected-output.ps1 "parseCidr('10.0.0.0/24')"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Expression
)

Write-Host "Input expression:" -ForegroundColor Cyan
Write-Host $Expression
Write-Host ""
Write-Host "Expected output (copy this for your test):" -ForegroundColor Cyan

# Run bicep console and filter out warnings
$output = $Expression | bicep console 2>&1 | Out-String
$lines = $output -split "`n" | Where-Object {
    $_ -notmatch "WARNING: The 'console' CLI command is an experimental feature" -and
    $_ -notmatch "Experimental features should be used for testing purposes only" -and
    $_.Trim() -ne ""
}

$result = ($lines -join "`n").Trim()
Write-Host $result
