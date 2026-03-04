#!/bin/bash
# Skill Health Check Script
# Tests connectivity of all direct API skills

SKILLS="/home/vision/.openclaw/skills"

echo "=========================================="
echo "  Skill Health Check"
echo "  $(date)"
echo "=========================================="
echo ""

PASSED=0
FAILED=0

test_skill() {
    local name=$1
    local dir=$2
    local cmd=$3

    echo -n "Testing $name... "
    if cd "$SKILLS/$dir" && timeout 10 node -e "$cmd" > /dev/null 2>/tmp/skill-test-$name.err; then
        echo "OK"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL"
        echo "  Error: $(cat /tmp/skill-test-$name.err 2>/dev/null | head -1)"
        FAILED=$((FAILED + 1))
    fi
}

test_skill "unifi-network" "unifi-network-direct" \
    "const { unifiListDevices } = require('./index'); unifiListDevices().then(() => process.exit(0)).catch(e => { console.error(e.message); process.exit(1); })"

test_skill "unifi-protect" "unifi-protect-direct" \
    "const { up_list_cameras } = require('./index'); up_list_cameras().then(() => process.exit(0)).catch(e => { console.error(e.message); process.exit(1); })"

test_skill "ha-direct" "ha-direct" \
    "const { haReadLogs } = require('./index'); haReadLogs().then(() => process.exit(0)).catch(e => { console.error(e.message); process.exit(1); })"

echo ""
echo "=========================================="
echo "  Results: $PASSED passed, $FAILED failed"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    echo "All skills healthy!"
    exit 0
else
    echo "Some skills are not responding."
    exit 1
fi
