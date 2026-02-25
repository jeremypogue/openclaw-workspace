#!/bin/bash
# Animal Tracker — Three Oaks Farm
# Phase 1: Queries HA for recent animal_detected events, applies cooldown debouncing,
# outputs JSON list of cameras needing vision analysis.
# Called by the Animal Tracker cron agent every 10 minutes.

set -euo pipefail

WORKSPACE="/home/vision/.openclaw/workspace"
PROFILES="$WORKSPACE/animal-profiles.json"
STATE_FILE="$WORKSPACE/animal-tracker-state.json"
SIGHTINGS="$WORKSPACE/animal-sightings.jsonl"
LOOKBACK_MINUTES=10

NOW_EPOCH=$(date +%s)

# All 22 animal_detected binary sensors (matches security-check.sh)
ANIMAL_SENSORS="binary_sensor.barn_animal_detected,binary_sensor.stalls_animal_detected,binary_sensor.stall1_animal_detected,binary_sensor.stall2_animal_detected,binary_sensor.stall3_animal_detected,binary_sensor.paddock1_animal_detected,binary_sensor.paddock2_animal_detected,binary_sensor.paddock5_animal_detected,binary_sensor.overwatch_animal_detected,binary_sensor.pond_animal_detected,binary_sensor.backyard_animal_detected,binary_sensor.front_yard_animal_detected,binary_sensor.patio_north_animal_detected,binary_sensor.pool_patio_animal_detected,binary_sensor.garage_animal_detected,binary_sensor.front_door_animal_detected,binary_sensor.back_door_animal_detected,binary_sensor.driveway_animal_detected,binary_sensor.driveentry_animal_detected,binary_sensor.mower_storage_animal_detected,binary_sensor.pool_animal_detected,binary_sensor.spa_animal_detected"

# Query HA history for the lookback period
HISTORY=$(mcporter call ha-mcp.ha_get_history entity_ids="$ANIMAL_SENSORS" start_time="${LOOKBACK_MINUTES}m" significant_changes_only=true 2>/dev/null || echo '[]')

# Extract cameras with activity (state went to "on" in the lookback window)
ACTIVE_CAMERAS=""
if command -v jq &>/dev/null && [ "$HISTORY" != "[]" ]; then
    ACTIVE_CAMERAS=$(echo "$HISTORY" | jq -r '
        [.[] | .entity_id as $eid |
            ($eid | split(".")[1] | split("_animal_detected")[0]) as $sensor |
            [.states[]? | select(.state == "on")] |
            {sensor: $sensor, count: length, last: (if length > 0 then .[-1].last_changed else null end)}
        ] | [.[] | select(.count > 0)] | .[].sensor
    ' 2>/dev/null || echo "")
fi

if [ -z "$ACTIVE_CAMERAS" ]; then
    echo "NO_ACTIVITY"
    exit 0
fi

# Load cooldown state
if [ -f "$STATE_FILE" ]; then
    STATE=$(cat "$STATE_FILE")
else
    STATE='{"last_analysis":{},"last_updated":null}'
fi

# Load profiles for camera classifications and cooldown rules
STALL_CAMERAS=$(jq -r '.camera_classifications.stall_cameras[]' "$PROFILES" 2>/dev/null)
PERIMETER_CAMERAS=$(jq -r '.camera_classifications.perimeter_cameras[]' "$PROFILES" 2>/dev/null)

# Build output: cameras that need vision analysis (not in cooldown)
CAMERAS_TO_ANALYZE="[]"

while IFS= read -r SENSOR; do
    [ -z "$SENSOR" ] && continue

    # Get the Protect camera name for this sensor
    PROTECT_CAM=$(jq -r --arg s "$SENSOR" '.sensor_to_camera_map[$s] // $s' "$PROFILES" 2>/dev/null)

    # Check cooldown — get last analysis info for this sensor
    LAST_ANALYSIS=$(echo "$STATE" | jq -r --arg s "$SENSOR" '.last_analysis[$s] // empty' 2>/dev/null)

    SKIP=false
    if [ -n "$LAST_ANALYSIS" ]; then
        LAST_TS=$(echo "$LAST_ANALYSIS" | jq -r '.timestamp // 0' 2>/dev/null)
        LAST_ANIMAL=$(echo "$LAST_ANALYSIS" | jq -r '.animal // ""' 2>/dev/null)
        ELAPSED_MIN=$(( (NOW_EPOCH - LAST_TS) / 60 ))

        # Unknown dogs never have cooldown
        if [ "$LAST_ANIMAL" != "unknown_dog" ]; then
            # Stall camera with horse in own stall → 60 min cooldown
            STALL_OWNER=$(jq -r --arg s "$SENSOR" '.stall_assignments[$s] // ""' "$PROFILES" 2>/dev/null)
            if [ -n "$STALL_OWNER" ] && [ "$LAST_ANIMAL" = "$STALL_OWNER" ]; then
                if [ "$ELAPSED_MIN" -lt 60 ]; then
                    SKIP=true
                fi
            # Perimeter camera → 15 min cooldown
            elif echo "$PERIMETER_CAMERAS" | grep -qw "$SENSOR"; then
                if [ "$ELAPSED_MIN" -lt 15 ]; then
                    SKIP=true
                fi
            # Same animal, same camera → 30 min cooldown
            elif [ -n "$LAST_ANIMAL" ] && [ "$ELAPSED_MIN" -lt 30 ]; then
                SKIP=true
            fi
            # Different animal on same camera → no cooldown (SKIP stays false)
        fi
    fi

    if [ "$SKIP" = false ]; then
        CAMERAS_TO_ANALYZE=$(echo "$CAMERAS_TO_ANALYZE" | jq \
            --arg sensor "$SENSOR" \
            --arg camera "$PROTECT_CAM" \
            '. + [{"sensor": $sensor, "camera": $camera}]')
    fi
done <<< "$ACTIVE_CAMERAS"

# Check if any cameras need analysis
COUNT=$(echo "$CAMERAS_TO_ANALYZE" | jq 'length')
if [ "$COUNT" -eq 0 ]; then
    echo "NO_ACTIVITY"
    exit 0
fi

echo "$CAMERAS_TO_ANALYZE" | jq -c '.'
