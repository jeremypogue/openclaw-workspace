# TOOLS.md - Local Environment

## MCP Servers (via mcporter)

All MCP tools are accessed via the `mcporter` CLI. The daemon runs in the background with keep-alive connections.

Quick reference:
- `mcporter list` — see all servers and tool counts
- `mcporter list <server> --schema` — see tool signatures
- `mcporter call <server.tool> key=value` — call a tool
- `mcporter daemon status` — check daemon health

### unifi-protect (13 tools)
UniFi Protect NVR at 10.0.201.1. Security cameras, snapshots, video clips.

Key tools:
- `unifi-protect.list_cameras` — list all cameras
- `unifi-protect.get_snapshot camera_id=<name>` — grab a live snapshot (returns base64 JPEG)
- `unifi-protect.get_video_clip camera_id=<name> minutes_ago=5 duration_seconds=30` — download a clip
- `unifi-protect.get_stream_url camera_id=<name>` — get RTSPS stream URLs
- `unifi-protect.set_camera_recording camera_id=<name> enabled=true` — toggle recording
- `unifi-protect.get_system_info` — NVR system status

### ha-mcp (91 tools)
Home Assistant at 10.0.101.254:8123. Smart home control, automations, entities, dashboards.

Key tools:
- `ha-mcp.ha_search_entities query=<term>` — find entities by name/type
- `ha-mcp.ha_turn_on entity_id=<id>` / `ha-mcp.ha_turn_off entity_id=<id>` — control devices
- `ha-mcp.ha_get_state entity_id=<id>` — get current state
- `ha-mcp.ha_get_history entity_id=<id>` — get history
- `ha-mcp.ha_config_list_areas` — list rooms/areas
- `ha-mcp.ha_get_automations` — list automations
- `ha-mcp.ha_trigger_automation automation_id=<id>` — trigger an automation

### pool-controller (19 tools)
nodejs-poolController at 10.0.101.253:4200. Pool and spa equipment management.

Key tools:
- `pool-controller.pool_get_state` — current pool/spa status
- `pool-controller.pool_set_circuit circuit_id=<id> state=<on/off>` — control circuits
- `pool-controller.pool_set_heat_setpoint body=<pool/spa> setpoint=<temp>` — adjust temps
- `pool-controller.pool_set_heat_mode body=<pool/spa> mode=<off/heater/solar>` — heat mode
- `pool-controller.pool_set_chlorinator level=<percent>` — chlorinator

### relay-equipment-manager (20 tools)
REM Unit 1 at 10.0.101.250:8080. Hardware relay and sensor control.

Key tools:
- `relay-equipment-manager.rem_get_feeds` — list output feeds
- `relay-equipment-manager.rem_set_feed_state feed_id=<id> state=<on/off>` — control relays
- `relay-equipment-manager.rem_get_triggers` — list input triggers
- `relay-equipment-manager.rem_get_i2c_devices` — list I2C devices (ADCs, sensors)

### relay-equipment-manager-2 (20 tools)
REM Unit 2 at 10.0.101.252:8080. Same tools as Unit 1, different hardware.

### unifi-network (5 tools)
UniFi Network controller at 192.168.1.1. Switches, APs, clients.

Key tools:
- `unifi-network.list_clients` — connected clients
- `unifi-network.list_devices` — network devices
- `unifi-network.get_device device_id=<id>` — device details

## Network Layout

| Device | IP | Purpose |
|---|---|---|
| UniFi Gateway | 192.168.1.1 | Network controller |
| UniFi Protect NVR | 10.0.201.1 | Camera NVR |
| Home Assistant | 10.0.101.254 | Smart home hub |
| Pool Controller | 10.0.101.253 | Pool/spa equipment |
| REM Unit 1 | 10.0.101.250 | Relay/sensor board |
| REM Unit 2 | 10.0.101.252 | Relay/sensor board |

## Camera Snapshot Rules (CRITICAL)

**Each camera snapshot uses ~30K-50K tokens.** Grabbing multiple snapshots in one session WILL fill the 131K context window and make the session unresponsive. Follow these rules strictly:

1. **NEVER grab more than 2 snapshots in a single conversation.** If the user asks about multiple cameras, pick the 2 most relevant.
2. **For "where is [animal]?" queries:** FIRST check the sightings log at `/home/vision/.openclaw/workspace/animal-sightings.jsonl`. Report what's there. Only grab a snapshot if the log is empty/stale AND the user specifically asks for a live check — and only check 1-2 cameras maximum.
3. **For security checks:** Run the security-check.sh script instead of grabbing snapshots. Only grab a snapshot if the user specifically asks to SEE a particular camera.
4. **For "check all cameras" or "scan the property":** Refuse to do this inline. Explain that bulk scanning should be done via the Animal Tracker cron job, or offer to check 1-2 specific cameras.

## Animal Tracking

Animal sightings are tracked by the **Animal Tracker** cron job (every 10 min) and logged to:
- Sightings log: `/home/vision/.openclaw/workspace/animal-sightings.jsonl`
- Animal profiles: `/home/vision/.openclaw/workspace/animal-profiles.json`

When asked about animal locations:
1. Read the sightings log: `tail -20 /home/vision/.openclaw/workspace/animal-sightings.jsonl`
2. Report the latest sighting per animal
3. If the log is empty/stale, say so and offer to check 1-2 specific cameras

Known animals: Dozer (boxer dog), Nona (black Percheron), Cruella (black horse, white face star), Scooby (black horse, white foot).

## Notes

- All MCP servers use STDIO transport, managed by mcporter daemon
- Tool filtering is in place — scheduling, GPIO, and system-destructive operations are excluded
- For camera snapshots, the image is returned as base64 JPEG — describe what you see
- When controlling equipment (relays, pool, heating), confirm with the user before acting
