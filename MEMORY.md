# Networking Devices

## UniFi Network — USE THE SKILL, NOT MCP
**The `unifi-network` MCP server has been removed.** All UniFi network queries go through the `unifi-network-direct` skill.

### How to call:
```bash
exec command="cd /home/vision/.openclaw/skills/unifi-network-direct && node -e \"const { unifiListDevices } = require('./index'); unifiListDevices().then(r => console.log(JSON.stringify(r, null, 2))).catch(console.error)\""
```

### DO NOT:
- Use `mcporter call unifi-network.*` — the MCP server no longer exists
- Use Home Assistant for UniFi devices — HA does not manage UniFi
- Fabricate device lists from memory — always call the tool

## Rules for Networking Tasks
1. **UniFi devices** (APs, switches, routers, clients): Use `unifi-network-direct` skill
2. **Home Assistant entities** (lights, sensors, switches): Use `ha-direct` skill
3. **UniFi cameras**: Use `unifi-protect-direct` skill
