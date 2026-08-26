#!/bin/bash

# MCP Users Server - Railway Test Script
# Tests all 5 tools of the MCP server running on Railway

set -e

RAILWAY_URL="https://claude-ia-mcp-tools-java-staging.up.railway.app"

echo "================================================"
echo "MCP Users Server - Railway Test"
echo "================================================"
echo ""
echo "Target: $RAILWAY_URL"
echo ""

# Verify curl is installed
if ! command -v curl &> /dev/null; then
    echo "ERROR: curl is not installed"
    exit 1
fi

# Function to send command via HTTP
test_tool() {
    local name=$1
    local command=$2

    echo "================================================"
    echo "Test: $name"
    echo "================================================"
    echo "Request:"
    echo "$command" | jq '.' 2>/dev/null || echo "$command"
    echo ""

    # Send command to MCP server via HTTP POST
    response=$(curl -s -X POST "$RAILWAY_URL" \
        -H "Content-Type: application/json" \
        -d "$command" 2>&1)

    if [ -z "$response" ]; then
        echo "Response: (no response received - server may not be running)"
        echo "Hint: Make sure the Railway app is deployed and running"
    else
        echo "Response:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    fi
    echo ""
}

# Check if server is reachable
echo "Checking server connectivity..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" "$RAILWAY_URL" 2>&1)
echo "HTTP Status: $http_code"
echo ""

if [ "$http_code" = "000" ] || [ "$http_code" = "003" ]; then
    echo "WARNING: Server is not reachable at $RAILWAY_URL"
    echo "Make sure:"
    echo "  1. The Railway app is deployed and running"
    echo "  2. The URL is correct"
    echo "  3. You have internet connectivity"
    echo ""
fi

# Test 1: Initialize
test_tool "Initialize Server" \
    '{"jsonrpc":"2.0","method":"initialize","id":1}'

# Test 2: List Tools
test_tool "List Tools" \
    '{"jsonrpc":"2.0","method":"tools/list","id":2}'

# Test 3: Get User
test_tool "Get User (ID: 1)" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"get_user","arguments":{"user_id":1}},"id":3}'

# Test 4: List Users
test_tool "List Users" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"list_users","arguments":{}},"id":4}'

# Test 5: Create User
test_tool "Create User (Test User)" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"create_user","arguments":{"name":"Test User","email":"test@example.com"}},"id":5}'

# Test 6: Update User
test_tool "Update User (ID: 1)" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"update_user","arguments":{"user_id":1,"name":"Updated User"}},"id":6}'

# Test 7: Delete User
test_tool "Delete User (ID: 1)" \
    '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"delete_user","arguments":{"user_id":1}},"id":7}'

echo "================================================"
echo "All tests completed!"
echo "================================================"
echo ""
echo "Note: If tests failed with connection errors,"
echo "the Railway server may not be configured for HTTP requests."
echo "The MCP server currently uses stdio mode (stdin/stdout)."
