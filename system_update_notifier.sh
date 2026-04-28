#!/bin/bash

# System Update Notifier Script
# Features: Checks for pending security updates on Debian/Ubuntu systems

echo "===== SYSTEM UPDATE NOTIFIER ====="

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if command_exists apt-get; then
    echo "Checking for updates (requires sudo for apt-get update)..."
    # Note: Running apt-get update might be slow and requires root
    sudo apt-get update -qq
    
    # Check for security updates
    if command_exists /usr/lib/update-notifier/apt-check; then
        UPDATES=$(/usr/lib/update-notifier/apt-check 2>&1)
        COUNT=$(echo "$UPDATES" | cut -d';' -f1)
        SECURITY=$(echo "$UPDATES" | cut -d';' -f2)
        echo "Total updates pending: $COUNT"
        echo "Security updates pending: $SECURITY"
    else
        # Fallback using apt list
        COUNT=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
        echo "Approximate updates pending: $((COUNT > 0 ? COUNT - 1 : 0))"
        echo "Run 'apt list --upgradable' for details."
    fi
    
    # Check if reboot is required
    if [ -f /var/run/reboot-required ]; then
        echo "⚠️  System reboot required!"
    fi
elif command_exists yum; then
    echo "Checking for updates via yum..."
    yum check-update -q
    if [ $? -eq 100 ]; then
        echo "Updates are available."
    else
        echo "No updates available."
    fi
else
    echo "Neither apt-get nor yum found. Skipping update check."
fi

echo "===== DONE ====="
