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

echo "[5] SSL/LetsEncrypt Status"
if dokku plugin:list | grep -q "letsencrypt"; then
    apps=$(dokku apps:list --ps | grep -vE "^===|^$" | awk '{print $1}')
    if [ -n "$apps" ] && [ "$apps" != "App" ]; then
        for app in $apps; do
            if [ "$app" == "App" ]; then continue; fi
            echo "--- App: $app ---"
            # Show letsencrypt report for the app
            dokku letsencrypt:app-report "$app" 2>/dev/null | grep -E "Status:|Enabled:|Domains:|Expiration date:" || echo "SSL not configured for $app"
        done
    else
        echo "No apps found to check SSL status."
    fi
else
    echo "dokku-letsencrypt plugin not found. Skipping SSL check."
fi
echo

echo "[6] Database Services Status"
# Check for common database plugins and list their services
DB_PLUGINS=("postgres" "mysql" "mariadb" "redis" "mongodb")
FOUND_DB_SERVICES=false

for plugin in "${DB_PLUGINS[@]}"; do
    # Use cat to avoid broken pipe if grep finishes early
    if dokku plugin:list | cat | grep -q "$plugin"; then
        echo "--- $plugin services ---"
        # list services for the plugin
        # Use a temporary file to avoid broken pipe when reading into a variable
        dokku "$plugin":list 2>/dev/null > "/tmp/dokku_${plugin}_services"
        services=$(grep -vE "^===|^$" "/tmp/dokku_${plugin}_services" | awk '{print $1}')
        rm -f "/tmp/dokku_${plugin}_services"
        if [ -n "$services" ] && [ "$services" != "Service" ]; then
            for service in $services; do
                if [ "$service" == "Service" ]; then continue; fi
                echo "Service: $service"
                # info command usually gives a good summary
                # Use cat to consume all output and avoid broken pipe
                dokku "$plugin":info "$service" 2>/dev/null | cat | grep -E "Status:|Running:|Exposed ports:|Config dir:|Data dir:" || echo "No status available"
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

echo "[7] Resource Usage (Docker Stats for Dokku)"
if command_exists docker; then
    # Filter docker stats to show only containers managed by dokku
    DOKKU_CONTAINERS=$(docker ps --filter "label=com.dokku.app-name" -q | xargs)
    # Also include database containers if possible (they usually have com.dokku.service-name label)
    DOKKU_SERVICE_CONTAINERS=$(docker ps --filter "label=com.dokku.service-name" -q | xargs)
    
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

echo "[8] Dokku Storage Usage"
DOKKU_LIB="/var/lib/dokku"
if [ -d "$DOKKU_LIB" ]; then
    sudo du -sh "$DOKKU_LIB" 2>/dev/null || echo "Permission denied for $DOKKU_LIB"
else
    echo "Dokku library directory $DOKKU_LIB not found."
fi

echo "===== DONE ====="
