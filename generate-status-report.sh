#!/bin/bash
# Daily Status Report Generator
# Generates a comprehensive status report including MCP health and system info

REPORT_FILE="/tmp/status-report-$(date +%Y%m%d-%H%M%S).txt"
DATE=$(date '+%A, %B %d %Y at %I:%M %p %Z')

echo "📊 DAILY STATUS REPORT" > "$REPORT_FILE"
echo "=====================" >> "$REPORT_FILE"
echo "Generated: $DATE" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# MCP Health Check
echo "🔌 MCP SERVER STATUS" >> "$REPORT_FILE"
echo "--------------------" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if bash /home/vision/.openclaw/workspace/mcp-health-check.sh >> "$REPORT_FILE" 2>&1; then
    MCP_STATUS="✅ All MCP servers healthy"
else
    MCP_STATUS="⚠️ Some MCP servers failed"
fi

echo "" >> "$REPORT_FILE"

# OpenClaw Gateway Status
echo "🦞 OPENCLAW GATEWAY" >> "$REPORT_FILE"
echo "-------------------" >> "$REPORT_FILE"
if openclaw status >> "$REPORT_FILE" 2>&1; then
    echo "" >> "$REPORT_FILE"
else
    echo "⚠️ Could not get gateway status" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# System Resources
echo "💻 SYSTEM RESOURCES" >> "$REPORT_FILE"
echo "-------------------" >> "$REPORT_FILE"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)" >> "$REPORT_FILE"
echo "Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')" >> "$REPORT_FILE"
echo "Memory:" >> "$REPORT_FILE"
free -h | grep -E "(Mem|Swap)" >> "$REPORT_FILE" 2>/dev/null || echo "  Memory info unavailable" >> "$REPORT_FILE"
echo "Disk Usage:" >> "$REPORT_FILE"
df -h / | tail -1 >> "$REPORT_FILE" 2>/dev/null || echo "  Disk info unavailable" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Network Check
echo "🌐 NETWORK STATUS" >> "$REPORT_FILE"
echo "-----------------" >> "$REPORT_FILE"
echo "Checking connectivity..." >> "$REPORT_FILE"
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ Internet: Connected" >> "$REPORT_FILE"
else
    echo "❌ Internet: Disconnected" >> "$REPORT_FILE"
fi

# Check key local hosts
for host in 192.168.1.1 10.0.101.254 10.0.201.1; do
    if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
        echo "✅ $host: Reachable" >> "$REPORT_FILE"
    else
        echo "❌ $host: Unreachable" >> "$REPORT_FILE"
    fi
done
echo "" >> "$REPORT_FILE"

# UniFi Network Devices - Check for offline devices
echo "📡 NETWORK DEVICES (UniFi)" >> "$REPORT_FILE"
echo "--------------------------" >> "$REPORT_FILE"
echo "Checking device status via unifi-network MCP..." >> "$REPORT_FILE"
UNIFI_DEVICES_JSON="/tmp/unifi-devices.json"
if mcporter call unifi-network.unifi_execute --args '{"tool": "unifi_list_devices"}' > "$UNIFI_DEVICES_JSON" 2>/tmp/unifi-error.log; then
    # Parse with jq if available, otherwise note it's available
    if command -v jq &> /dev/null; then
        TOTAL_DEVICES=$(jq -r '.devices | length' "$UNIFI_DEVICES_JSON" 2>/dev/null || echo "0")
        echo "📊 Total devices: $TOTAL_DEVICES" >> "$REPORT_FILE"
        # Check for devices with status != "online"
        OFFLINE_COUNT=$(jq -r '[.devices[] | select(.status != "online" or .adopted != true)] | length' "$UNIFI_DEVICES_JSON" 2>/dev/null || echo "0")
        DISCONNECTED_COUNT=$(jq -r '[.devices[] | select(.status == "disconnected" or .status == "offline" or .status == "pending" or .adopted != true)] | length' "$UNIFI_DEVICES_JSON" 2>/dev/null || echo "0")
        if [ "$DISCONNECTED_COUNT" -gt 0 ]; then
            echo "" >> "$REPORT_FILE"
            echo "⚠️ $DISCONNECTED_COUNT device(s) offline/disconnected:" >> "$REPORT_FILE"
            jq -r '.devices[] | select(.status != "online" or .adopted != true) | "  ❌ \(.name // "Unknown") (\(.type // .model // "device")) - Status: \(.status // "unknown")"' "$UNIFI_DEVICES_JSON" >> "$REPORT_FILE" 2>/dev/null || true
        elif [ "$TOTAL_DEVICES" -gt 0 ]; then
            echo "✅ All network devices connected" >> "$REPORT_FILE"
        fi
    else
        # No jq, just count total devices from .devices array
        TOTAL_DEVICES=$(grep -c '"name"' "$UNIFI_DEVICES_JSON" 2>/dev/null || echo "0")
        echo "📊 $TOTAL_DEVICES devices in inventory (install jq for detailed status)" >> "$REPORT_FILE"
    fi
else
    echo "❌ Failed to query UniFi network devices" >> "$REPORT_FILE"
    cat /tmp/unifi-error.log 2>/dev/null | head -5 >> "$REPORT_FILE" || true
fi
echo "" >> "$REPORT_FILE"

# UniFi Protect Cameras - Check for offline cameras
echo "📹 SECURITY CAMERAS (UniFi Protect)" >> "$REPORT_FILE"
echo "------------------------------------" >> "$REPORT_FILE"
echo "Checking camera status via unifi-protect MCP..." >> "$REPORT_FILE"
PROTECT_CAMERAS_JSON="/tmp/protect-cameras.json"
if mcporter call unifi-protect.list_cameras > "$PROTECT_CAMERAS_JSON" 2>/tmp/protect-error.log; then
    if command -v jq &> /dev/null; then
        TOTAL_CAMERAS=$(jq -r '.total // (.cameras | length) // 0' "$PROTECT_CAMERAS_JSON" 2>/dev/null || echo "0")
        OFFLINE_CAMERAS=$(jq -r '[.cameras[] | select(.state != "CONNECTED" or .is_connected != true)] | length' "$PROTECT_CAMERAS_JSON" 2>/dev/null || echo "0")
        echo "📊 Total cameras: $TOTAL_CAMERAS" >> "$REPORT_FILE"
        if [ "$OFFLINE_CAMERAS" -gt 0 ]; then
            echo "" >> "$REPORT_FILE"
            echo "⚠️ $OFFLINE_CAMERAS camera(s) offline/disconnected:" >> "$REPORT_FILE"
            jq -r '.cameras[] | select(.state != "CONNECTED" or .is_connected != true) | "  ❌ \(.name // "Unknown") (\(.model // "camera")) - State: \(.state)"' "$PROTECT_CAMERAS_JSON" >> "$REPORT_FILE" 2>/dev/null || true
        else
            echo "✅ All cameras online and connected" >> "$REPORT_FILE"
        fi
    else
        TOTAL_CAMERAS=$(grep -c '"name"' "$PROTECT_CAMERAS_JSON" 2>/dev/null || echo "0")
        echo "📊 $TOTAL_CAMERAS cameras registered (install jq for detailed status)" >> "$REPORT_FILE"
    fi
else
    echo "❌ Failed to query UniFi Protect cameras" >> "$REPORT_FILE"
    cat /tmp/protect-error.log 2>/dev/null | head -5 >> "$REPORT_FILE" || true
fi
echo "" >> "$REPORT_FILE"

# Home Assistant - Check for automation status and errors
echo "🏠 HOME ASSISTANT (Last 24h)" >> "$REPORT_FILE"
echo "-----------------------------" >> "$REPORT_FILE"

# Check for disabled automations
echo "Checking automation states..." >> "$REPORT_FILE"
HA_AUTOMATIONS_JSON="/tmp/ha-automations.json"
if mcporter call ha-mcp.ha_search_entities query="automation" limit=200 > "$HA_AUTOMATIONS_JSON" 2>/tmp/ha-automations-error.log; then
    if command -v jq &> /dev/null; then
        TOTAL_AUTOMATIONS=$(jq -r '.total_matches // (.results | length) // 0' "$HA_AUTOMATIONS_JSON" 2>/dev/null || echo "0")
        DISABLED_AUTOMATIONS=$(jq -r '[.results[]? | select(.state == "off")] | length' "$HA_AUTOMATIONS_JSON" 2>/dev/null || echo "0")
        echo "📊 Total automations: $TOTAL_AUTOMATIONS" >> "$REPORT_FILE"
        if [ "$DISABLED_AUTOMATIONS" -gt 0 ]; then
            echo "⚠️ $DISABLED_AUTOMATIONS automation(s) disabled:" >> "$REPORT_FILE"
            jq -r '.results[] | select(.state == "off") | "  ⏸️ \(.friendly_name // .entity_id)"' "$HA_AUTOMATIONS_JSON" >> "$REPORT_FILE" 2>/dev/null | head -10 || true
        fi
        echo "" >> "$REPORT_FILE"
    fi
fi

echo "Checking automation errors via ha-mcp..." >> "$REPORT_FILE"
HA_LOGBOOK_JSON="/tmp/ha-logbook.json"
if mcporter call ha-mcp.ha_get_logbook hours_back=24 limit=200 > "$HA_LOGBOOK_JSON" 2>/tmp/ha-error.log; then
    if command -v jq &> /dev/null; then
        # Look for error/warning patterns in messages
        ERROR_COUNT=$(jq -r '[.entries[]? | select(.message | type == "string") | select(.message | ascii_downcase | test("error|fail|unavailable|exception|timeout|unable to call|could not"))] | length' "$HA_LOGBOOK_JSON" 2>/dev/null || echo "0")
        WARNING_COUNT=$(jq -r '[.entries[]? | select(.message | type == "string") | select(.entity_id | contains("automation")) | select(.message | ascii_downcase | test("unavailable|warning|error|fail"))] | length' "$HA_LOGBOOK_JSON" 2>/dev/null || echo "0")
        
        # Count automation-related entries with issues
        AUTO_ERROR_COUNT=$(jq -r '[.entries[]? | select(.entity_id | contains("automation")) | select(.message | type == "string") | select(.message | ascii_downcase | test("error|fail|exception|timeout|unable"))] | length' "$HA_LOGBOOK_JSON" 2>/dev/null || echo "0")
        
        echo "📊 Automation errors (24h): $AUTO_ERROR_COUNT" >> "$REPORT_FILE"
        
        if [ "$AUTO_ERROR_COUNT" -gt 0 ]; then
            echo "" >> "$REPORT_FILE"
            echo "⚠️ Automation errors found:" >> "$REPORT_FILE"
            jq -r '.entries[] | select(.entity_id | contains("automation")) | select(.message | type == "string") | select(.message | ascii_downcase | test("error|fail|exception|timeout|unable")) | "  ❌ \(.name // "Unknown"): \(.message)"' "$HA_LOGBOOK_JSON" >> "$REPORT_FILE" 2>/dev/null | head -20 || true
        fi
        
        # Show unavailable entity warnings (common automation issue)
        UNAVAIL_COUNT=$(jq -r '[.entries[]? | select(.message | type == "string") | select(.message | ascii_downcase | contains("unavailable"))] | length' "$HA_LOGBOOK_JSON" 2>/dev/null || echo "0")
        if [ "$UNAVAIL_COUNT" -gt 0 ]; then
            echo "" >> "$REPORT_FILE"
            echo "⚠️ $UNAVAIL_COUNT unavailable entity warnings:" >> "$REPORT_FILE"
            jq -r '.entries[] | select(.message | type == "string") | select(.message | ascii_downcase | contains("unavailable")) | "  ⚠️ \(.name // "Unknown"): \(.message)"' "$HA_LOGBOOK_JSON" >> "$REPORT_FILE" 2>/dev/null | head -10 || true
        fi
        
        if [ "$AUTO_ERROR_COUNT" -eq 0 ] && [ "$UNAVAIL_COUNT" -eq 0 ]; then
            echo "✅ No automation errors in last 24h" >> "$REPORT_FILE"
        fi
    else
        echo "📊 Log entries retrieved (install jq for detailed error analysis)" >> "$REPORT_FILE"
    fi
else
    echo "❌ Failed to query Home Assistant logbook" >> "$REPORT_FILE"
    cat /tmp/ha-error.log 2>/dev/null | head -3 >> "$REPORT_FILE" || true
fi
echo "" >> "$REPORT_FILE"

# Pool/Spa Status
echo "🏊 POOL/SPA STATUS" >> "$REPORT_FILE"
echo "------------------" >> "$REPORT_FILE"
POOL_STATE_JSON="/tmp/pool-state.json"
if mcporter call pool-controller.pool_get_state > "$POOL_STATE_JSON" 2>/tmp/pool-error.log; then
    if command -v jq &> /dev/null; then
        # Pool Pump
        POOL_PUMP_RPM=$(jq -r '.pumps[] | select(.name == "Pool") | .rpm // 0' "$POOL_STATE_JSON" 2>/dev/null)
        if [ -n "$POOL_PUMP_RPM" ] && [ "$POOL_PUMP_RPM" != "0" ] && [ "$POOL_PUMP_RPM" != "null" ]; then
            echo "Pool Pump: 🟢 ON at ${POOL_PUMP_RPM} RPM" >> "$REPORT_FILE"
        else
            echo "Pool Pump: ⚪ OFF" >> "$REPORT_FILE"
        fi
        
        # Spa Pump
        SPA_PUMP_RPM=$(jq -r '.pumps[] | select(.name == "Spa") | .rpm // 0' "$POOL_STATE_JSON" 2>/dev/null)
        if [ -n "$SPA_PUMP_RPM" ] && [ "$SPA_PUMP_RPM" != "0" ] && [ "$SPA_PUMP_RPM" != "null" ]; then
            echo "Spa Pump: 🟢 ON at ${SPA_PUMP_RPM} RPM" >> "$REPORT_FILE"
        else
            echo "Spa Pump: ⚪ OFF" >> "$REPORT_FILE"
        fi
        
        # Spa Heater
        SPA_HEATER_STATUS=$(jq -r '.temps.bodies[1].heatStatus.desc // "off"' "$POOL_STATE_JSON" 2>/dev/null)
        SPA_TEMP=$(jq -r '.temps.bodies[1].temp // "N/A"' "$POOL_STATE_JSON" 2>/dev/null)
        if [ "$SPA_HEATER_STATUS" != "off" ] && [ "$SPA_HEATER_STATUS" != "Off" ]; then
            if [ "$SPA_TEMP" != "N/A" ] && [ "$SPA_TEMP" != "null" ]; then
                echo "Spa Heater: 🔥 ON at ${SPA_TEMP}°F" >> "$REPORT_FILE"
            else
                echo "Spa Heater: 🔥 ON" >> "$REPORT_FILE"
            fi
        else
            echo "Spa Heater: ⚪ OFF" >> "$REPORT_FILE"
        fi
    else
        echo "📊 Pool state retrieved (install jq for detailed status)" >> "$REPORT_FILE"
    fi
else
    echo "❌ Failed to query pool controller" >> "$REPORT_FILE"
    cat /tmp/pool-error.log 2>/dev/null | head -3 >> "$REPORT_FILE" || true
fi
echo "" >> "$REPORT_FILE"

echo "========================" >> "$REPORT_FILE"
echo "Report complete: $REPORT_FILE"

# Output the report
cat "$REPORT_FILE"
