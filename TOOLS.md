# TOOLS.md - Local Environment

## How to call MCP tools (Legacy)
ALL tools go through `exec`:
```bash
exec command="mcporter call <server>.<tool> key=value key2=value2"
```

## Home Assistant Direct API Integration
**Replaces MCP for all Home Assistant interactions.**

### Direct Tool Calls
Use `exec` to call tools directly:
```bash
# Get state of an entity
exec command="cd /home/vision/.openclaw/skills/ha-direct && node -e \"const { haGetState } = require('./index'); haGetState('sensor.sun_next_dawn').then(console.log).catch(console.error)\"

# Call a service (e.g., turn on a light)
exec command="cd /home/vision/.openclaw/skills/ha-direct && node -e \"const { haCallService } = require('./index'); haCallService('light', 'turn_on', 'light.shop').then(console.log).catch(console.error)\"

# Create a dashboard
exec command="cd /home/vision/.openclaw/skills/ha-direct && node -e \"const { haCreateDashboard } = require('./index'); haCreateDashboard('Test Dashboard').then(console.log).catch(console.error)\"

# Read logs
exec command="cd /home/vision/.openclaw/skills/ha-direct && node -e \"const { haReadLogs } = require('./index'); haReadLogs().then(console.log).catch(console.error)\"

# Search for entities
exec command="cd /home/vision/.openclaw/skills/ha-direct && node -e \"const { haSearchEntities } = require('./index'); haSearchEntities('sensor').then(console.log).catch(console.error)\"
```

## Known Entities
- **Shop Speaker**: `media_player.workshop_door_speaker`
- **Pool Pump**: `switch.pool_pump`

## Other Servers (Legacy)
- `unifi-protect` — cameras: `get_snapshot camera_id=<name>`
- `pool-controller` — pool: `pool_get_state`, `pool_set_heat_setpoint`
- `relay-equipment-manager` — relay boards
- `unifi-network` — network: `list_clients`, `list_devices`

## Scripts
**Daily Status Report** — generates a full system status report:
```bash
exec command="bash /home/vision/.openclaw/workspace/generate-status-report.sh"
```

## Camera Snapshots
Each snapshot uses ~30K-50K tokens. Max 2 per conversation.

## Animal Tracking
Sightings: `animal-sightings.jsonl` — read for "where is Dozer?" queries.
Known animals: Dozer (boxer), Nona (Percheron), Cruella (white face star), Scooby (white foot).