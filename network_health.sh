#!/bin/bash

# Network Health Check Script
# Features: Ping tests, HTTP status checks, Latency reporting

# Configuration
TARGETS=("8.8.8.8" "google.com" "github.com")
HTTP_URLS=("https://google.com" "https://github.com")
PING_COUNT=3

echo "===== NETWORK HEALTH CHECK ====="

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

echo "[1] Ping Tests..."
for target in "${TARGETS[@]}"; do
    echo -n "Pinging $target... "
    if command_exists ping; then
        # Handle different ping versions (macOS/Linux)
        PING_OUT=$(ping -c $PING_COUNT "$target" 2>&1)
        if [ $? -eq 0 ]; then
            LATENCY=$(echo "$PING_OUT" | tail -1 | awk -F '/' '{print $5}')
            echo "OK (avg latency: ${LATENCY}ms)"
        else
            echo "FAILED"
        fi
    else
        echo "ping command not found."
    fi
done

echo
echo "[2] HTTP Status Checks..."
if command_exists curl; then
    for url in "${HTTP_URLS[@]}"; do
        echo -n "Checking $url... "
        STATUS=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 5 "$url")
        if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 301 ] || [ "$STATUS" -eq 302 ]; then
            echo "OK ($STATUS)"
        else
            echo "FAILED ($STATUS)"
        fi
    done
else
    echo "curl command not found."
fi

echo
echo "[3] Local Interface Check..."
if command_exists ip; then
    ip -brief addr
elif command_exists ifconfig; then
    ifconfig | grep -E "inet |status:" | head -n 10
fi

echo "===== DONE ====="
