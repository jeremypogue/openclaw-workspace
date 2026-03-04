# TOOLS.md - Local Environment

## Skills (Primary Tool Interface)
Skills are Node.js modules in `/home/vision/.openclaw/skills/`. Call them via `exec`.

### UniFi Network — `unifi-network-direct`
**For all UniFi network devices (APs, switches, routers, clients).**
```bash
# List all devices
exec command="cd /home/vision/.openclaw/skills/unifi-network-direct && node -e \"const { unifiListDevices } = require('./index'); unifiListDevices().then(r => console.log(JSON.stringify(r, null, 2))).catch(console.error)\""

# Reboot a device by name
exec command="cd /home/vision/.openclaw/skills/unifi-network-direct && node -e \"const { unifiRebootDevice } = require('./index'); unifiRebootDevice('AP-Barn').then(r => console.log(JSON.stringify(r))).catch(console.error)\""
```

### UniFi Protect — `unifi-protect-direct`
**For cameras, snapshots, and event logs.**
```bash
# List all cameras
exec command="cd /home/vision/.openclaw/skills/unifi-protect-direct && node -e \"const { up_list_cameras } = require('./index'); up_list_cameras().then(r => console.log(JSON.stringify(r, null, 2))).catch(console.error)\""

# Get snapshot from a camera
exec command="cd /home/vision/.openclaw/skills/unifi-protect-direct && node -e \"const { up_get_snapshot } = require('./index'); up_get_snapshot('camera_id_here').then(r => console.log(JSON.stringify(r))).catch(console.error)\""

# Get recent events
exec command="cd /home/vision/.openclaw/skills/unifi-protect-direct && node -e \"const { up_get_event_logs } = require('./index'); up_get_event_logs().then(r => console.log(JSON.stringify(r, null, 2))).catch(console.error)\""
```

### Home Assistant — `ha-direct`
**For all Home Assistant entities (sensors, lights, switches, media players).**
```bash
# Get entity state
exec command="cd /home/vision/.openclaw/skills/ha-direct && node -e \"const { haGetState } = require('./index'); haGetState('sensor.sun_next_dawn').then(console.log).catch(console.error)\""

# Call a service
exec command="cd /home/vision/.openclaw/skills/ha-direct && node -e \"const { haCallService } = require('./index'); haCallService('light', 'turn_on', 'light.shop').then(console.log).catch(console.error)\""

# Search entities
exec command="cd /home/vision/.openclaw/skills/ha-direct && node -e \"const { haSearchEntities } = require('./index'); haSearchEntities('sensor').then(console.log).catch(console.error)\""

# Create dashboard
exec command="cd /home/vision/.openclaw/skills/ha-direct && node -e \"const { haCreateDashboard } = require('./index'); haCreateDashboard('Test Dashboard').then(console.log).catch(console.error)\""

# Read logs
exec command="cd /home/vision/.openclaw/skills/ha-direct && node -e \"const { haReadLogs } = require('./index'); haReadLogs().then(console.log).catch(console.error)\""
```

## Known Entities
- **Shop Speaker**: `media_player.workshop_door_speaker`
- **Pool Pump**: `switch.pool_pump`

## Scripts
**Daily Status Report:**
```bash
exec command="bash /home/vision/.openclaw/workspace/generate-status-report.sh"
```

## Animal Tracking
Sightings: `animal-sightings.jsonl` — read for "where is Dozer?" queries.
Known animals: Dozer (boxer), Nona (Percheron), Cruella (white face star), Scooby (white foot).

## IMPORTANT
- **Do NOT use `mcporter call`** — all MCP servers have been removed
- **Do NOT use Home Assistant for UniFi devices** — HA does not manage UniFi
- All integrations now use direct API skills in `/home/vision/.openclaw/skills/`
