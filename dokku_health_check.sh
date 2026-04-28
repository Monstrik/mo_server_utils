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
    # The first line is usually a header like '=== my apps'
    # We skip lines starting with '=' or empty lines
    apps=$(dokku apps:list --ps | grep -vE "^===|^$" | awk '{print $1}')

if [ -z "$apps" ] || [ "$apps" == "App" ]; then
    echo "No apps found."
else
    for app in $apps; do
        if [ "$app" == "App" ]; then continue; fi
        echo "--- App: $app ---"
        dokku ps:report "$app" --status 2>/dev/null || echo "Could not get status for $app"
        echo "Details:"
        dokku apps:report "$app" --status --deployed 2>/dev/null | grep -E "Status:|Deployed:"
        echo
    done
fi

echo "[4] Plugin Status"
dokku plugin:list
echo

echo "[5] Database Services Status"
# Check for common database plugins and list their services
DB_PLUGINS=("postgres" "mysql" "mariadb" "redis" "mongodb")
FOUND_DB_SERVICES=false

for plugin in "${DB_PLUGINS[@]}"; do
    if dokku plugin:list | grep -q "$plugin"; then
        echo "--- $plugin services ---"
        # list services for the plugin
        services=$(dokku "$plugin":list 2>/dev/null | grep -vE "^===|^$" | awk '{print $1}')
        if [ -n "$services" ] && [ "$services" != "Service" ]; then
            for service in $services; do
                if [ "$service" == "Service" ]; then continue; fi
                echo "Service: $service"
                dokku "$plugin":report "$service" --status 2>/dev/null | grep "Status:" || echo "No status available"
            done
            FOUND_DB_SERVICES=true
        else
            echo "No $plugin services found."
        fi
        echo
    fi
done

if [ "$FOUND_DB_SERVICES" = false ]; then
    echo "No supported database plugins found."
    echo
fi

echo "[6] Resource Usage (Docker Stats for Dokku)"
if command_exists docker; then
    # Filter docker stats to show only containers managed by dokku
    DOKKU_CONTAINERS=$(docker ps --filter "label=com.dokku.app-name" -q)
    # Also include database containers if possible (they usually have com.dokku.service-name label)
    DOKKU_SERVICE_CONTAINERS=$(docker ps --filter "label=com.dokku.service-name" -q)
    
    ALL_CONTAINERS="$DOKKU_CONTAINERS $DOKKU_SERVICE_CONTAINERS"
    
    if [ -n "$(echo $ALL_CONTAINERS | tr -d ' ')" ]; then
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $ALL_CONTAINERS 2>/dev/null
    else
        echo "No running Dokku app or service containers found."
    fi
else
    echo "Docker command not found, cannot show resource usage."
fi
echo

echo "[7] Dokku Storage Usage"
DOKKU_LIB="/var/lib/dokku"
if [ -d "$DOKKU_LIB" ]; then
    sudo du -sh "$DOKKU_LIB" 2>/dev/null || echo "Permission denied for $DOKKU_LIB"
else
    echo "Dokku library directory $DOKKU_LIB not found."
fi

echo "===== DONE ====="
