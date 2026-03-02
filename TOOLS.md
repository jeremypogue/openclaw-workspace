# TOOLS.md - Local Environment

## How to call MCP tools

ALL tools go through `exec`:
```
exec command="mcporter call <server>.<tool> key=value key2=value2"
```

## Home Assistant (ha-mcp)

**Search for entities:**
```
exec command="mcporter call ha-mcp.ha_search_entities query=shop domain_filter=media_player"
```

**Get entity state:**
```
exec command="mcporter call ha-mcp.ha_get_state entity_id=sensor.battery_soc"
```

**Control anything (lights, switches, media, etc.):**
```
exec command="mcporter call ha-mcp.ha_call_service domain=media_player service=play_media entity_id=media_player.workshop_door_speaker"
exec command="mcporter call ha-mcp.ha_call_service domain=light service=turn_on entity_id=light.shop"
exec command="mcporter call ha-mcp.ha_call_service domain=switch service=toggle entity_id=switch.pool_pump"
```

**There is NO `ha_turn_on` tool. Use `ha_call_service` for ALL service calls.**

## Known Entities

- Shop speaker: `media_player.workshop_door_speaker`

## Other Servers

- `unifi-protect` — cameras: `get_snapshot camera_id=<name>`
- `pool-controller` — pool: `pool_get_state`, `pool_set_heat_setpoint`
- `relay-equipment-manager` — relay boards
- `unifi-network` — network: `list_clients`, `list_devices`

Run `mcporter list <server>` for full tool list.

## Camera Snapshots

Each snapshot uses ~30K-50K tokens. Max 2 per conversation.

## Animal Tracking

Sightings: `animal-sightings.jsonl` — read for "where is Dozer?" queries.
Known animals: Dozer (boxer), Nona (Percheron), Cruella (white face star), Scooby (white foot).
