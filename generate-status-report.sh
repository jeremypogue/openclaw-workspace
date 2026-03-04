#!/bin/bash
# Daily Status Report Generator
# Uses direct API skills (not MCP servers)

REPORT_FILE="/tmp/status-report-$(date +%Y%m%d-%H%M%S).txt"
DATE=$(date '+%A, %B %d %Y at %I:%M %p %Z')
SKILLS="/home/vision/.openclaw/skills"

echo "DAILY STATUS REPORT" > "$REPORT_FILE"
echo "=====================" >> "$REPORT_FILE"
echo "Generated: $DATE" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# OpenClaw Gateway Status
echo "OPENCLAW GATEWAY" >> "$REPORT_FILE"
echo "-------------------" >> "$REPORT_FILE"
if systemctl --user is-active openclaw-gateway > /dev/null 2>&1; then
    echo "Gateway: Active" >> "$REPORT_FILE"
else
    echo "Gateway: INACTIVE" >> "$REPORT_FILE"
fi
if systemctl --user is-active llmrouter > /dev/null 2>&1; then
    echo "LLMRouter: Active" >> "$REPORT_FILE"
else
    echo "LLMRouter: INACTIVE" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# System Resources
echo "SYSTEM RESOURCES" >> "$REPORT_FILE"
echo "-------------------" >> "$REPORT_FILE"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)" >> "$REPORT_FILE"
echo "Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')" >> "$REPORT_FILE"
echo "Memory:" >> "$REPORT_FILE"
free -h | grep -E "(Mem|Swap)" >> "$REPORT_FILE" 2>/dev/null || echo "  Memory info unavailable" >> "$REPORT_FILE"
echo "Disk Usage:" >> "$REPORT_FILE"
df -h / | tail -1 >> "$REPORT_FILE" 2>/dev/null || echo "  Disk info unavailable" >> "$REPORT_FILE"

# GPU
if command -v nvidia-smi &> /dev/null; then
    echo "GPU:" >> "$REPORT_FILE"
    nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader 2>/dev/null >> "$REPORT_FILE" || echo "  GPU info unavailable" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Network Check
echo "NETWORK STATUS" >> "$REPORT_FILE"
echo "-----------------" >> "$REPORT_FILE"
if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    echo "Internet: Connected" >> "$REPORT_FILE"
else
    echo "Internet: DISCONNECTED" >> "$REPORT_FILE"
fi

for host in 192.168.1.1; do
    if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
        echo "$host (UDM): Reachable" >> "$REPORT_FILE"
    else
        echo "$host (UDM): UNREACHABLE" >> "$REPORT_FILE"
    fi
done
echo "" >> "$REPORT_FILE"

# UniFi Network Devices
echo "NETWORK DEVICES (UniFi)" >> "$REPORT_FILE"
echo "--------------------------" >> "$REPORT_FILE"
UNIFI_JSON="/tmp/unifi-devices.json"
if cd "$SKILLS/unifi-network-direct" && node -e "const { unifiListDevices } = require('./index'); unifiListDevices().then(r => console.log(JSON.stringify(r))).catch(e => { console.error(e.message); process.exit(1); })" > "$UNIFI_JSON" 2>/tmp/unifi-error.log; then
    if command -v jq &> /dev/null; then
        TOTAL_DEVICES=$(jq -r '.data | length // 0' "$UNIFI_JSON" 2>/dev/null || jq -r '. | length // 0' "$UNIFI_JSON" 2>/dev/null || echo "0")
        echo "Total devices: $TOTAL_DEVICES" >> "$REPORT_FILE"

        # Check for offline devices
        OFFLINE=$(jq -r '[(.data // .)[] | select(.state != "ONLINE" and .state != "online" and .state != 1)] | length' "$UNIFI_JSON" 2>/dev/null || echo "0")
        if [ "$OFFLINE" -gt 0 ] 2>/dev/null; then
            echo "OFFLINE devices: $OFFLINE" >> "$REPORT_FILE"
            jq -r '(.data // .)[] | select(.state != "ONLINE" and .state != "online" and .state != 1) | "  - \(.name // "Unknown") (\(.model // "device")) state=\(.state // "unknown")"' "$UNIFI_JSON" >> "$REPORT_FILE" 2>/dev/null || true
        else
            echo "All devices online" >> "$REPORT_FILE"
        fi
    else
        echo "Devices retrieved (install jq for details)" >> "$REPORT_FILE"
    fi
else
    echo "Failed to query UniFi network" >> "$REPORT_FILE"
    cat /tmp/unifi-error.log 2>/dev/null | head -3 >> "$REPORT_FILE" || true
fi
echo "" >> "$REPORT_FILE"

# UniFi Protect Cameras
echo "SECURITY CAMERAS (UniFi Protect)" >> "$REPORT_FILE"
echo "------------------------------------" >> "$REPORT_FILE"
PROTECT_JSON="/tmp/protect-cameras.json"
if cd "$SKILLS/unifi-protect-direct" && node -e "const { up_list_cameras } = require('./index'); up_list_cameras().then(r => console.log(JSON.stringify(r))).catch(e => { console.error(e.message); process.exit(1); })" > "$PROTECT_JSON" 2>/tmp/protect-error.log; then
    if command -v jq &> /dev/null; then
        TOTAL_CAMERAS=$(jq -r '.total // (.cameras | length) // (. | length) // 0' "$PROTECT_JSON" 2>/dev/null || echo "0")
        echo "Total cameras: $TOTAL_CAMERAS" >> "$REPORT_FILE"

        OFFLINE_CAMERAS=$(jq -r '[(.cameras // .)[] | select(.state != "CONNECTED" and .is_connected != true)] | length' "$PROTECT_JSON" 2>/dev/null || echo "0")
        if [ "$OFFLINE_CAMERAS" -gt 0 ] 2>/dev/null; then
            echo "OFFLINE cameras: $OFFLINE_CAMERAS" >> "$REPORT_FILE"
            jq -r '(.cameras // .)[] | select(.state != "CONNECTED" and .is_connected != true) | "  - \(.name // "Unknown") state=\(.state // "unknown")"' "$PROTECT_JSON" >> "$REPORT_FILE" 2>/dev/null || true
        else
            echo "All cameras online" >> "$REPORT_FILE"
        fi
    else
        echo "Cameras retrieved (install jq for details)" >> "$REPORT_FILE"
    fi
else
    echo "Failed to query UniFi Protect" >> "$REPORT_FILE"
    cat /tmp/protect-error.log 2>/dev/null | head -3 >> "$REPORT_FILE" || true
fi
echo "" >> "$REPORT_FILE"

# Home Assistant
echo "HOME ASSISTANT" >> "$REPORT_FILE"
echo "-----------------------------" >> "$REPORT_FILE"
HA_JSON="/tmp/ha-status.json"
if cd "$SKILLS/ha-direct" && node -e "const { haReadLogs } = require('./index'); haReadLogs().then(r => console.log(JSON.stringify(r))).catch(e => { console.error(e.message); process.exit(1); })" > "$HA_JSON" 2>/tmp/ha-error.log; then
    echo "Home Assistant: Connected" >> "$REPORT_FILE"
    if command -v jq &> /dev/null; then
        ERROR_COUNT=$(jq -r '[.[]? | select(.message? | type == "string") | select(.message | ascii_downcase | test("error|fail|unavailable"))] | length' "$HA_JSON" 2>/dev/null || echo "0")
        if [ "$ERROR_COUNT" -gt 0 ] 2>/dev/null; then
            echo "Errors in logs: $ERROR_COUNT" >> "$REPORT_FILE"
        else
            echo "No errors in recent logs" >> "$REPORT_FILE"
        fi
    fi
else
    echo "Home Assistant: UNREACHABLE" >> "$REPORT_FILE"
    cat /tmp/ha-error.log 2>/dev/null | head -3 >> "$REPORT_FILE" || true
fi
echo "" >> "$REPORT_FILE"

# Docker / Services
echo "SERVICES" >> "$REPORT_FILE"
echo "------------------" >> "$REPORT_FILE"
if command -v docker &> /dev/null; then
    RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)
    STOPPED=$(docker ps -a --filter "status=exited" --format '{{.Names}}' 2>/dev/null | wc -l)
    echo "Docker containers: $RUNNING running, $STOPPED stopped" >> "$REPORT_FILE"
    if [ "$STOPPED" -gt 0 ]; then
        docker ps -a --filter "status=exited" --format '  - {{.Names}} (exited {{.Status}})' 2>/dev/null >> "$REPORT_FILE" || true
    fi
fi

# Ollama
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:11434/api/tags 2>/dev/null | grep -q "200"; then
    OLLAMA_MODELS=$(curl -s http://127.0.0.1:11434/api/tags 2>/dev/null | jq -r '.models | length' 2>/dev/null || echo "?")
    echo "Ollama: Active ($OLLAMA_MODELS models)" >> "$REPORT_FILE"
else
    echo "Ollama: UNREACHABLE" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

echo "========================" >> "$REPORT_FILE"
echo "Report complete: $REPORT_FILE"

# Output the report
cat "$REPORT_FILE"
