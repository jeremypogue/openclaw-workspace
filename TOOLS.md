# TOOLS.md - Local Environment

## MCP Servers (via mcporter CLI)

**IMPORTANT: `mcporter` is a CLI command, NOT a native tool.** To call MCP tools, use the `exec` tool:
```
exec command="mcporter call <server.tool> key=value"
```
Do NOT try to call `mcporter` as a tool name — it will fail with "Tool not found".

**If exec fails on the first try, DO NOT retry.** Report the error to the user and stop.

### Available MCP Servers
- `unifi-protect` (13 tools) — cameras, snapshots, video clips. Key: `get_snapshot camera_id=<name>`
- `ha-mcp` (91 tools) — Home Assistant. Key: `ha_get_state`, `ha_turn_on/off`, `ha_search_entities`
- `pool-controller` (19 tools) — pool/spa. Key: `pool_get_state`, `pool_set_heat_setpoint`
- `relay-equipment-manager` (20 tools) — relay/sensor board at 10.0.101.250
- `relay-equipment-manager-2` (20 tools) — relay/sensor board at 10.0.101.252
- `unifi-network` (5 tools) — network devices. Key: `list_clients`, `list_devices`

Run `mcporter list <server> --schema` to see full tool signatures.

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

**Each camera snapshot uses ~30K-50K tokens.** Grabbing multiple snapshots in one session WILL fill the context window and make the session unresponsive. Follow these rules strictly:

1. **NEVER grab more than 2 snapshots in a single conversation.** If the user asks about multiple cameras, pick the 2 most relevant.
2. **For "where is [animal]?" queries:** FIRST check the sightings log at `/home/vision/.openclaw/workspace/animal-sightings.jsonl`. Report what's there. Only grab a snapshot if the log is empty/stale AND the user specifically asks for a live check — and only check 1-2 cameras maximum.
3. **For security checks:** Run the security-check.sh script instead of grabbing snapshots. Only grab a snapshot if the user specifically asks to SEE a particular camera.
4. **For "check all cameras" or "scan the property":** Refuse to do this inline. Explain that bulk scanning should be done via the Animal Tracker cron job, or offer to check 1-2 specific cameras.

## Animal Tracking

Animal sightings are tracked by the **Animal Tracker** cron job (every 10 min) and logged to:
- Sightings log: `/home/vision/.openclaw/workspace/animal-sightings.jsonl`
- Animal profiles: `/home/vision/.openclaw/workspace/animal-profiles.json`

When asked about animal locations:
1. Read the sightings log ONCE: `read /home/vision/.openclaw/workspace/animal-sightings.jsonl`
2. If the file has entries, report the latest sighting per animal
3. If the file is EMPTY or does not exist, say "No sightings have been recorded yet. The Animal Tracker cron runs every 10 minutes — want me to check 1-2 specific cameras instead?"
4. **NEVER read the same file more than once.** If the file is empty on the first read, it will be empty on the second read too. Move on.

Known animals: Dozer (boxer dog), Nona (black Percheron), Cruella (black horse, white face star), Scooby (black horse, white foot).

## Notes

- All MCP servers use STDIO transport, managed by mcporter daemon
- Tool filtering is in place — scheduling, GPIO, and system-destructive operations are excluded
- For camera snapshots, the image is returned as base64 JPEG — describe what you see
- When controlling equipment (relays, pool, heating), confirm with the user before acting
