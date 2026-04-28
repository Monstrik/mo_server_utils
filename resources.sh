#!/bin/bash

# Utility script to monitor server resources (CPU, Memory, Docker, Storage, Connections)

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

echo "================= TOP CPU ================="
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head -n 11
echo

echo "================= TOP MEMORY ================="
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%mem | head -n 11
echo

echo "================= LOAD ================="
uptime
echo

echo "================= DOCKER CONTAINERS ================="
if command_exists docker; then
  docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "Docker is running but stats are unavailable."
else
  echo "Docker command not found."
fi
echo

echo "================= HEAVY DIRECTORIES ================="
DOKKU_DIR="/var/lib/dokku"
if [[ -d "$DOKKU_DIR" ]]; then
  du -h --max-depth=1 "$DOKKU_DIR" 2>/dev/null | sort -hr | head -n 10
else
  echo "Directory $DOKKU_DIR not found. Showing current directory instead:"
  du -h --max-depth=1 . 2>/dev/null | sort -hr | head -n 10
fi
echo

echo "================= OPEN CONNECTIONS ================="
if command_exists ss; then
  ss -tulnp | head -n 20
elif command_exists netstat; then
  netstat -tunlp | head -n 20
else
  echo "Neither 'ss' nor 'netstat' found."
fi
echo

echo "================= DONE ================="