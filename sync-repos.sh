#!/bin/bash
# Repo Auto-Sync Script — Three Oaks Farm
# Commits and pushes changes to all versioned repos
# Called by cron every 15 minutes

set -euo pipefail

WORKSPACE="/home/vision/.openclaw/workspace"
LOG_FILE="$WORKSPACE/sync-repos.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S CST')] $1" | tee -a "$LOG_FILE"
}

sync_repo() {
    local REPO_DIR="$1"
    local REPO_NAME="$2"
    
    if [ ! -d "$REPO_DIR/.git" ]; then
        log "❌ $REPO_NAME: No git repo at $REPO_DIR"
        return 1
    fi
    
    cd "$REPO_DIR"
    
    # Check for changes
    STATUS=$(git status --porcelain 2>/dev/null || echo "")
    
    if [ -z "$STATUS" ]; then
        log "✅ $REPO_NAME: No changes"
        return 0
    fi
    
    # Add, commit, push
    git add -A 2>/dev/null || true
    git diff --cached --quiet && { log "⚠️ $REPO_NAME: Nothing to commit after add"; return 0; }
    
    COMMIT_MSG="Auto-sync: $(date '+%Y-%m-%d %H:%M CST')"
    git commit -m "$COMMIT_MSG" 2>/dev/null || { log "❌ $REPO_NAME: Commit failed"; return 1; }
    
    git push 2>&1 | tee -a "$LOG_FILE" || { log "❌ $REPO_NAME: Push failed"; return 1; }
    
    log "✅ $REPO_NAME: Synced"
    return 0
}

log "=== Repo Sync Started ==="

# OpenClaw Workspace
sync_repo "$WORKSPACE" "openclaw-workspace"

# MCP Server Repos
sync_repo "/home/vision/unifi-protect-mcp-server" "unifi-protect-mcp-server"
sync_repo "/home/vision/nodejs-pool-controller-mcp" "nodejs-pool-controller-mcp"
sync_repo "/home/vision/relay-equipment-manager-mcp" "relay-equipment-manager-mcp"
sync_repo "/home/vision/ha-mcp" "ha-mcp"
sync_repo "/home/vision/unifi-network-mcp" "unifi-network-mcp"

# Ollama Config
sync_repo "/home/vision/ollama-config" "ollama-config"

log "=== Repo Sync Complete ==="
