#!/bin/bash

# MCP Users Server - Railway Test Script
# Tests all 5 tools of the MCP server running on Railway via WebSocket

RAILWAY_URL="wss://claude-ia-mcp-tools-java-staging.up.railway.app"

echo "================================================"
echo "MCP Users Server - Railway WebSocket Test"
echo "================================================"
echo ""
echo "Target: $RAILWAY_URL"
echo ""

# Function to install websocat
install_websocat() {
    echo "Installing websocat..."
    echo ""

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo "Detected macOS with Homebrew"
            brew install websocat
            return $?
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux - detect distribution
        if command -v pacman &> /dev/null; then
            echo "Detected Arch Linux (pacman)"
            sudo pacman -Sy websocat
            return $?
        elif command -v apt-get &> /dev/null; then
            echo "Detected Debian/Ubuntu (apt-get)"
            sudo apt-get update
            sudo apt-get install -y websocat
            return $?
        elif command -v yum &> /dev/null; then
            echo "Detected RHEL/CentOS/Fedora (yum)"
            sudo yum install -y websocat
            return $?
        elif command -v dnf &> /dev/null; then
            echo "Detected Fedora (dnf)"
            sudo dnf install -y websocat
            return $?
        elif command -v zypper &> /dev/null; then
            echo "Detected openSUSE (zypper)"
            sudo zypper install -y websocat
            return $?
        fi
    elif [[ "$OSTYPE" == "cygwin"* ]]; then
        # Cygwin
        echo "Detected Cygwin"

        # Try apt-cyg if available
        if command -v apt-cyg &> /dev/null; then
            echo "Installing via apt-cyg..."
            apt-cyg install websocat
            return $?
        else
            echo "apt-cyg not found. Installing apt-cyg first..."
            curl -s https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg > apt-cyg
            chmod +x apt-cyg
            mv apt-cyg /usr/local/bin/
            apt-cyg install websocat
            return $?
        fi
    elif [[ "$OSTYPE" == "msys" ]]; then
        # Git Bash / Windows
        echo "Detected Git Bash / Windows"
        if command -v choco &> /dev/null; then
            echo "Chocolatey found"
            choco install websocat
            return $?
        fi
    fi

    # Fallback 1: Try cargo if available (works on all platforms)
    if command -v cargo &> /dev/null; then
        echo "Installing via cargo (Rust)..."
        cargo install websocat
        return $?
    fi

    # Fallback 2: Clone and compile from source
    if command -v git &> /dev/null && command -v cargo &> /dev/null; then
        echo "Cloning websocat from GitHub and compiling from source..."
        echo ""

        TEMP_DIR=$(mktemp -d)
        trap "rm -rf $TEMP_DIR" EXIT

        cd "$TEMP_DIR" || return 1

        git clone https://github.com/vi/websocat.git --depth 1
        cd websocat || return 1

        echo "Compiling websocat (this may take a few minutes)..."
        cargo build --release

        if [ -f target/release/websocat ]; then
            echo "Installation successful!"
            sudo mv target/release/websocat /usr/local/bin/ || cp target/release/websocat ~/.local/bin/
            return 0
        fi
        return 1
    fi

    echo ""
    echo "ERROR: Could not automatically install websocat"
    echo ""
    echo "Manual installation options:"
    echo ""
    echo "macOS:"
    echo "  brew install websocat"
    echo ""
    echo "Arch Linux:"
    echo "  sudo pacman -Sy websocat"
    echo ""
    echo "Ubuntu/Debian/Linux:"
    echo "  sudo apt-get update && sudo apt-get install -y websocat"
    echo ""
    echo "Fedora/RHEL/CentOS:"
    echo "  sudo dnf install -y websocat   (Fedora 22+)"
    echo "  sudo yum install -y websocat   (CentOS/RHEL 7)"
    echo ""
    echo "openSUSE:"
    echo "  sudo zypper install -y websocat"
    echo ""
    echo "Cygwin:"
    echo "  curl -s https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg > apt-cyg"
    echo "  chmod +x apt-cyg"
    echo "  sudo mv apt-cyg /usr/local/bin/"
    echo "  apt-cyg install websocat"
    echo ""
    echo "Windows (Git Bash):"
    echo "  choco install websocat"
    echo ""
    echo "Universal (requires Rust):"
    echo "  cargo install websocat"
    echo ""
    echo "Manual download:"
    echo "  https://github.com/vi/websocat/releases"
    return 1
}

# Check if websocat is installed
if ! command -v websocat &> /dev/null; then
    echo "websocat not found. Attempting to install..."
    echo ""

    if ! install_websocat; then
        exit 1
    fi

    echo ""
    echo "websocat installed successfully!"
    echo ""
fi

# Function to send command via WebSocket
test_tool() {
    local name=$1
    local command=$2

    echo "================================================"
    echo "Test: $name"
    echo "================================================"
    echo "Request:"
    echo "$command" | jq '.' 2>/dev/null || echo "$command"
    echo ""

    # Send command to MCP server via WebSocket
    response=$(echo "$command" | websocat "$RAILWAY_URL" 2>&1 | head -1)

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
if timeout 5 websocat "$RAILWAY_URL" </dev/null 2>&1 | grep -q "error\|refused"; then
    echo "WARNING: Server is not reachable at $RAILWAY_URL"
    echo "Make sure:"
    echo "  1. The Railway app is deployed and running"
    echo "  2. The WebSocket server is properly configured"
    echo "  3. You have internet connectivity"
    echo ""
else
    echo "Server is reachable"
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
