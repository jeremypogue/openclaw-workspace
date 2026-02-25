#!/bin/bash
# MCP Server Health Check Script
# Tests connectivity and basic functionality of all configured MCP servers

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  MCP Server Health Check"
echo "  $(date)"
echo "=========================================="
echo ""

# Track results
PASSED=0
FAILED=0

# Function to test an MCP server
test_server() {
    local name=$1
    local tool=$2
    local params=$3

    echo -n "Testing $name... "
    if mcporter call "$tool" $params > /tmp/mcp-test-$name.json 2>/tmp/mcp-test-$name.err; then
        echo -e "${GREEN}OK${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Error: $(cat /tmp/mcp-test-$name.err | head -1)"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Test mcporter daemon first
echo -n "Checking mcporter daemon... "
if mcporter daemon status > /tmp/mcp-daemon-status.json 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    echo "  mcporter daemon not responding"
    FAILED=$((FAILED + 1))
    echo ""
    echo "Cannot continue without mcporter daemon."
    exit 1
fi
echo ""

# Test each MCP server
test_server "unifi-protect" "unifi-protect.list_cameras" ""
test_server "unifi-network" "unifi-network.list_devices" ""
test_server "ha-mcp" "ha-mcp.ha_config_list_areas" ""
test_server "pool-controller" "pool-controller.pool_get_state" ""
test_server "relay-equipment-manager" "relay-equipment-manager.rem_get_feeds" ""
test_server "relay-equipment-manager-2" "relay-equipment-manager-2.rem_get_feeds" ""

echo ""
echo "=========================================="
echo "  Results: $PASSED passed, $FAILED failed"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All MCP servers are healthy!${NC}"
    exit 0
else
    echo -e "${RED}Some MCP servers are not responding.${NC}"
    exit 1
fi
