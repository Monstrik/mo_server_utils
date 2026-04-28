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
APPS_LIST=$(dokku apps:list | cat)
echo "$APPS_LIST"
echo

echo "[3] Running Containers & Status"
# Check which apps are running and their status
# We reuse APPS_LIST if already fetched, or fetch it here
if [ -z "$APPS_LIST" ]; then
    APPS_LIST=$(dokku apps:list | cat)
fi
apps=$(echo "$APPS_LIST" | grep -vE "^===|^$" | awk '{print $1}')

if [ -z "$apps" ] || [ "$apps" == "App" ]; then
    echo "No apps found."
else
    for app in $apps; do
        if [ "$app" == "App" ]; then continue; fi
        echo "--- App: $app ---"
        # Use cat to fully consume output and avoid broken pipe
        PS_STATUS=$(dokku ps:report "$app" 2>/dev/null | cat)
        if [ -n "$PS_STATUS" ]; then
            echo "$PS_STATUS" | grep -iE "Status:|Running:|Deployed:|Internal port:" || echo "$PS_STATUS" | head -n 5
        else
            echo "No process status available for $app"
        fi
        
        echo "Details:"
        # Use cat and capture to variable
        APPS_REPORT=$(dokku apps:report "$app" 2>/dev/null | cat)
        if [ -n "$APPS_REPORT" ]; then
            echo "$APPS_REPORT" | grep -iE "Status:|Deployed:|App dir:|Git sha:" || echo "$APPS_REPORT" | head -n 5
        else
            echo "Could not get report for $app"
        fi
        echo
    done
fi

echo "[4] Plugin Status"
PLUGINS=$(dokku plugin:list | cat)
echo "$PLUGINS"
echo

echo "[5] SSL/LetsEncrypt Status"
# Check if letsencrypt plugin is installed - use the already fetched PLUGINS list
if echo "$PLUGINS" | grep -q "letsencrypt"; then
    if [ -z "$APPS_LIST" ]; then
        APPS_LIST=$(dokku apps:list | cat)
    fi
    apps=$(echo "$APPS_LIST" | grep -vE "^===|^$" | awk '{print $1}')
    if [ -n "$apps" ] && [ "$apps" != "App" ]; then
        SSL_FOUND=false
        for app in $apps; do
            if [ "$app" == "App" ]; then continue; fi
            # Show letsencrypt report for the app
            # Use cat to avoid broken pipe and check if enabled first
            LE_REPORT=$(dokku letsencrypt:app-report "$app" 2>/dev/null | cat)
            if echo "$LE_REPORT" | grep -qiE "Enabled:[[:space:]]*true"; then
                echo "--- App: $app ---"
                echo "$LE_REPORT" | grep -iE "Status:|Enabled:|Domains:|Expiration date:"
                SSL_FOUND=true
            fi
        done
        if [ "$SSL_FOUND" = false ]; then
            echo "No apps have LetsEncrypt SSL enabled."
        fi
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
    # Check if plugin is installed using the already fetched PLUGINS list
    if echo "$PLUGINS" | grep -q "$plugin"; then
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
