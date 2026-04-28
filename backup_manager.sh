#!/bin/bash

# Backup Manager Script
# Features: Local backups, compression, rotation of old backups

# Configuration
SOURCE_DIR="${1:-/var/lib/dokku}"
BACKUP_DIR="${2:-/var/backups/server_utils}"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_$TIMESTAMP.tar.gz"
FORCE=false

# Check for force flag (must be checked carefully if other args are used)
for arg in "$@"; do
    if [[ "$arg" == "-f" ]] || [[ "$arg" == "--force" ]]; then
        FORCE=true
    fi
done

echo "===== BACKUP MANAGER ====="

if [ "$FORCE" = false ]; then
    echo "⚠️  WARNING: This script creates backups and DELETES old backups older than $RETENTION_DAYS days in $BACKUP_DIR."
    read -p "Are you sure you want to proceed? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

# Ensure backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR" 2>/dev/null || { echo "Error: Could not create backup directory. Check permissions."; exit 1; }
fi

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Warning: Source directory $SOURCE_DIR not found."
    echo "Falling back to current directory for backup."
    SOURCE_DIR="."
fi

echo "Source: $SOURCE_DIR"
echo "Destination: $BACKUP_DIR/$BACKUP_NAME"

# Perform backup
echo "Starting compression..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "Backup completed successfully: $BACKUP_NAME"
    ls -lh "$BACKUP_DIR/$BACKUP_NAME"
else
    echo "Error: Backup failed."
    exit 1
fi

# Rotate old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -exec rm -v {} \;

echo "===== DONE ====="
