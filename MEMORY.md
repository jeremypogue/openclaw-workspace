# Networking Devices
- **UniFi Network Skill**: Use the **UniFi Network** skill (via `unifi-network` MCP server or Home Assistant integration) for all UniFi-related devices (access points, switches, clients).

## Rules for Networking Tasks
1. **For UniFi devices**: Always use the **UniFi Network** skill (e.g., `unifi-network` MCP server or Home Assistant integration).
2. **For Home Assistant entities**: Use the `ha-direct` skill when interacting with Home Assistant directly.
3. **For direct UniFi API access**: Use the `mcporter` tool to call the `unifi-network` server.