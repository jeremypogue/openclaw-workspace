# TOOLS.md - Local Environment

## MCP Servers

Access via `exec command="mcporter call <server.tool> key=value"`.

- `unifi-protect` — cameras, snapshots (`get_snapshot camera_id=<name>`)
- `ha-mcp` — Home Assistant (`ha_get_state`, `ha_turn_on/off`, `ha_search_entities`)
- `pool-controller` — pool/spa (`pool_get_state`, `pool_set_heat_setpoint`)
- `relay-equipment-manager` / `relay-equipment-manager-2` — relay boards
- `unifi-network` — network devices (`list_clients`, `list_devices`)

Run `mcporter list <server> --schema` for full tool signatures.

## Camera Snapshots

Each snapshot uses ~30K-50K tokens. Max 2 per conversation. For bulk checks, use the Animal Tracker cron or security-check.sh script.

## Animal Tracking

Sightings log: `/home/vision/.openclaw/workspace/animal-sightings.jsonl`
Profiles: `/home/vision/.openclaw/workspace/animal-profiles.json`

When asked about animal locations:
1. Read the sightings log once
2. If it has entries, report the latest per animal
3. If empty, say "No sightings recorded yet" and offer to check 1-2 cameras

Known animals: Dozer (boxer), Nona (Percheron), Cruella (white face star), Scooby (white foot).
