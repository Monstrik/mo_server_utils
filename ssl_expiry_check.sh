#!/bin/bash

# SSL Expiry Check Script
# Features: Checks SSL certificate expiration for domains using openssl

# Configuration
DOMAINS=("google.com" "github.com") # Add your domains here
DAYS_THRESHOLD=30

echo "===== SSL EXPIRY CHECK ====="

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if ! command_exists openssl; then
    echo "Error: openssl command not found."
    exit 1
fi

for domain in "${DOMAINS[@]}"; do
    echo -n "Checking $domain... "
    
    # Get expiry date using openssl
    EXPIRY_DATE=$(echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
    
    if [ -z "$EXPIRY_DATE" ]; then
        echo "FAILED (could not retrieve certificate)"
        continue
    fi
    
    # Convert to seconds
    EXPIRY_SEC=$(date -d "$EXPIRY_DATE" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$EXPIRY_DATE" +%s 2>/dev/null)
    CURRENT_SEC=$(date +%s)
    DIFF_SEC=$((EXPIRY_SEC - CURRENT_SEC))
    DIFF_DAYS=$((DIFF_SEC / 86400))
    
    if [ $DIFF_DAYS -lt 0 ]; then
        echo "EXPIRED! ($EXPIRY_DATE)"
    elif [ $DIFF_DAYS -lt $DAYS_THRESHOLD ]; then
        echo "WARNING: Expires in $DIFF_DAYS days ($EXPIRY_DATE)"
    else
        echo "OK (Expires in $DIFF_DAYS days)"
    fi
done

echo "===== DONE ====="
