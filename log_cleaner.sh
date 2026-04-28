#!/bin/bash

# Log Cleaner Script
# Features: Identify large logs, remove old compressed logs, trigger logrotate

# Configuration
LOG_DIR="/var/log"
THRESHOLD_MB=100
MAX_AGE_DAYS=30

echo "===== LOG CLEANER ====="

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

echo "[1] Identifying Large Log Files (> ${THRESHOLD_MB}MB)..."
# Find files larger than threshold in LOG_DIR (non-recursive for safety)
find "$LOG_DIR" -maxdepth 2 -type f -size +"${THRESHOLD_MB}M" -exec ls -lh {} \; 2>/dev/null

echo
echo "[2] Cleaning Compressed Logs older than $MAX_AGE_DAYS days..."
# Dry run first, but here we'll actually remove them if they match
find "$LOG_DIR" -name "*.gz" -type f -mtime +$MAX_AGE_DAYS -exec rm -v {} \; 2>/dev/null || echo "No old .gz files found or permission denied."

echo
echo "[3] Checking Logrotate Status..."
if [ -f "/var/lib/logrotate/status" ] || [ -f "/var/lib/logrotate.status" ]; then
    ls -l /var/lib/logrotate*status
    echo "Last logrotate run info:"
    tail -n 5 /var/lib/logrotate*status 2>/dev/null
else
    echo "Logrotate status file not found."
fi

echo
echo "[4] Manual Logrotate Trigger (optional)..."
echo "To manually trigger logrotate, run: sudo logrotate -f /etc/logrotate.conf"

echo "===== DONE ====="
