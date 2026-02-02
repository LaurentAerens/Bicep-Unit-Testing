#!/bin/bash

# Helper script to get expected output for a Bicep expression
# Usage: ./get-expected-output.sh "parseCidr('10.0.0.0/24')"

if [ -z "$1" ]; then
    echo "Usage: $0 \"bicep-expression\""
    echo ""
    echo "Example: $0 \"length([1, 2, 3])\""
    echo ""
    echo "This will output the result from bicep console,"
    echo "which you can use as the 'expected' value in your test."
    exit 1
fi

echo "Input expression:"
echo "$1"
echo ""
echo "Expected output (copy this for your test):"

# Run bicep console and filter out warnings
echo "$1" | bicep console 2>&1 | grep -v "WARNING: The 'console' CLI command is an experimental feature" | grep -v "Experimental features should be used for testing purposes only" | sed '/^$/d'
