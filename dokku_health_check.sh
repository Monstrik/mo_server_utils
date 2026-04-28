#!/bin/bash

# Dokku Health Check Script
# Features: App status, container stats, plugin list, and report

echo "===== DOKKU HEALTH CHECK ====="

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if ! command_exists dokku; then
    echo "Error: dokku command not found."
    exit 1
fi

echo "[1] Dokku Version"
dokku version
echo

echo "[2] Apps Status"
dokku apps:list
echo

echo "[3] Running Containers & Status"
# Check which apps are running and their status
# Skipping the header "my apps" or similar
apps=$(dokku apps:list | grep -vE "^===|^$" | awk '{print $1}')

if [ -z "$apps" ]; then
    echo "No apps found."
else
    for app in $apps; do
        echo "--- App: $app ---"
        dokku ls "$app" 2>/dev/null || echo "Could not get status for $app"
        echo "Report:"
        dokku apps:report "$app" --status --deployed 2>/dev/null | grep -E "Status:|Deployed:"
        echo
    done
fi

echo "[4] Plugin Status"
dokku plugin:list
echo

echo "[5] Resource Usage (Docker Stats for Dokku)"
if command_exists docker; then
    # Filter docker stats to show only containers managed by dokku
    DOKKU_CONTAINERS=$(docker ps --filter "label=com.dokku.app-name" -q)
    if [ -n "$DOKKU_CONTAINERS" ]; then
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $DOKKU_CONTAINERS 2>/dev/null
    else
        echo "No running Dokku containers found."
    fi
else
    echo "Docker command not found, cannot show resource usage."
fi
echo

echo "[6] Dokku Storage Usage"
DOKKU_LIB="/var/lib/dokku"
if [ -d "$DOKKU_LIB" ]; then
    sudo du -sh "$DOKKU_LIB" 2>/dev/null || echo "Permission denied for $DOKKU_LIB"
else
    echo "Dokku library directory $DOKKU_LIB not found."
fi

echo "===== DONE ====="
