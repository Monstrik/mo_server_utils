#!/bin/bash

# User Activity Monitor Script
# Features: Current logins, active processes, non-standard user alerts

# Configuration
ALLOWED_USERS=("root" "deploy" "$(whoami)")
# Add more users to ALLOWED_USERS as needed

echo "===== USER ACTIVITY MONITOR ====="

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

echo "[1] Currently Logged-in Users..."
if command_exists who; then
    who
else
    echo "Command 'who' not found."
fi

echo
echo "[2] Active User Sessions and Tasks..."
if command_exists w; then
    w
else
    echo "Command 'w' not found."
fi

echo
echo "[3] Security Alert: Non-standard Users..."
CURRENT_USERS=$(who | awk '{print $1}' | sort -u)
FOUND_SUSPICIOUS=0

for user in $CURRENT_USERS; do
    IS_ALLOWED=0
    for allowed in "${ALLOWED_USERS[@]}"; do
        if [ "$user" == "$allowed" ]; then
            IS_ALLOWED=1
            break
        fi
    done
    
    if [ $IS_ALLOWED -eq 0 ]; then
        echo "⚠️ ALERT: Non-standard user detected: $user"
        FOUND_SUSPICIOUS=1
    fi
done

if [ $FOUND_SUSPICIOUS -eq 0 ]; then
    echo "No suspicious users currently logged in."
fi

echo
echo "[4] Last 5 Logins..."
if command_exists last; then
    last -n 5
else
    echo "Command 'last' not found."
fi

echo "===== DONE ====="
