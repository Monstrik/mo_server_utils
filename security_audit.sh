#!/bin/bash

# Incident check script for security auditing

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Configurable parameters
CHECK_DATE="${1:-Mar 18}"
TARGET_USER="${2:-deploy}"
AUTH_LOG="/var/log/auth.log"

echo "===== SECURITY AUDIT ====="
echo "Date: $CHECK_DATE"
echo "Target User: $TARGET_USER"

echo
echo "[1] Checking suspicious logins ($CHECK_DATE)..."
if command_exists last; then
  LOGINS=$(last -a | grep "$CHECK_DATE")
  if [ -z "$LOGINS" ]; then
    echo "No logins found on $CHECK_DATE → suspicious (likely external)"
  else
    echo "$LOGINS"
  fi
else
  echo "Command 'last' not found. Skipping login check."
  LOGINS=""
fi

echo
echo "[2] Checking successful SSH logins..."
if [ -f "$AUTH_LOG" ]; then
  grep "Accepted" "$AUTH_LOG" | tail -n 10
else
  echo "$AUTH_LOG not found. Skipping SSH check."
fi

echo
echo "[3] Checking sudo activity..."
if [ -f "$AUTH_LOG" ]; then
  SUDO=$(grep "sudo:" "$AUTH_LOG" | tail -n 20)
  if [ -z "$SUDO" ]; then
    echo "No sudo activity found → good"
  else
    echo "$SUDO"
  fi
else
  echo "$AUTH_LOG not found. Skipping sudo check."
fi

echo
echo "[4] Checking root sessions..."
if [ -f "$AUTH_LOG" ]; then
  ROOT=$(grep "session opened for user root" "$AUTH_LOG")
  if [ -z "$ROOT" ]; then
    echo "No root sessions → good"
  else
    echo "$ROOT" | tail -n 10
  fi
else
  echo "$AUTH_LOG not found. Skipping root session check."
fi

echo
echo "[5] Searching for miner files..."
if command_exists sudo && command_exists find; then
  MINER=$(sudo find / -name "xmrig" 2>/dev/null | head -n 5)
  if [ -z "$MINER" ]; then
    echo "No xmrig files found (clean)"
  else
    echo "Found miner files:"
    echo "$MINER"
  fi
else
  echo "Required commands (sudo/find) not found. Skipping miner search."
fi

echo
echo "[6] Checking bash history ($TARGET_USER)..."
HISTORY_FILE="/home/$TARGET_USER/.bash_history"
if [ -f "$HISTORY_FILE" ]; then
  HIT=$(grep -iE "xmrig|wget|curl" "$HISTORY_FILE")
  if [ -z "$HIT" ]; then
    echo "No suspicious commands in history"
  else
    echo "Suspicious commands found:"
    echo "$HIT"
  fi
else
  echo "History file $HISTORY_FILE not found. Skipping history audit."
  HIT=""
fi

echo
echo "===== FINAL VERDICT ====="

if [ -z "$LOGINS" ] && [ -z "$HIT" ]; then
  echo "→ Likely EXTERNAL attack (bot/exploit)"
else
  echo "→ POSSIBLE internal activity (check manually)"
fi

echo "===== DONE ====="
