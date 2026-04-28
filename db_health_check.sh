#!/bin/bash

# Database Health Check Script
# Features: Service status, connection counts, disk usage for common DBs

echo "===== DATABASE HEALTH CHECK ====="

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# PostgreSQL
echo "[1] PostgreSQL"
if command_exists psql; then
    if pg_isready >/dev/null 2>&1; then
        echo "Status: Online"
        echo -n "Connections: "
        sudo -u postgres psql -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null || echo "Unknown (check permissions)"
    else
        echo "Status: Offline or not accepting connections"
    fi
else
    echo "psql command not found. Skipping PostgreSQL check."
fi
echo

# MySQL / MariaDB
echo "[2] MySQL/MariaDB"
if command_exists mysqladmin; then
    if mysqladmin ping >/dev/null 2>&1; then
        echo "Status: Online"
        mysqladmin status | awk '{print $1, $2, $3, $4}'
    else
        echo "Status: Offline"
    fi
else
    echo "mysqladmin command not found. Skipping MySQL check."
fi
echo

# Redis
echo "[3] Redis"
if command_exists redis-cli; then
    if redis-cli ping | grep -q PONG; then
        echo "Status: Online"
        redis-cli info | grep -E "connected_clients|used_memory_human|role"
    else
        echo "Status: Offline"
    fi
else
    echo "redis-cli command not found. Skipping Redis check."
fi
echo

# MongoDB
echo "[4] MongoDB"
if command_exists mongosh; then
    if mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        echo "Status: Online"
        mongosh --eval "db.serverStatus().connections" | grep -E "current|available"
    else
        echo "Status: Offline"
    fi
elif command_exists mongo; then
     if mongo --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        echo "Status: Online"
    else
        echo "Status: Offline"
    fi
else
    echo "mongo/mongosh command not found. Skipping MongoDB check."
fi
echo

# Disk Usage for DB directories
echo "[5] DB Storage Usage"
DB_PATHS=("/var/lib/postgresql" "/var/lib/mysql" "/var/lib/mongodb" "/var/lib/redis")
for path in "${DB_PATHS[@]}"; do
    if [ -d "$path" ]; then
        du -sh "$path" 2>/dev/null || echo "Permission denied for $path"
    fi
done

echo "===== DONE ====="
