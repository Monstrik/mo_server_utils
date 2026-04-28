#!/bin/bash

echo "=== Server Age Check ==="

# --- CPU ---
cpu=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
echo -e "\n[CPU]\n$cpu"

# --- CPU Release Year ---
release_year="Unknown"

if [[ "$cpu" == *"W-21"* ]]; then
  release_year=2017
elif [[ "$cpu" == *"E5-"*"v4"* ]]; then
  release_year=2016
elif [[ "$cpu" == *"E5-"*"v3"* ]]; then
  release_year=2014
elif [[ "$cpu" == *"E5-"*"v2"* ]]; then
  release_year=2013
elif [[ "$cpu" == *"E5-"*"v1"* ]]; then
  release_year=2012
fi

echo -e "\n[Estimated CPU Release Year]\n$release_year"

# --- System ---
echo -e "\n[System Model]"
sudo dmidecode -t system | grep -E "Manufacturer|Product Name"

# --- BIOS ---
bios=$(sudo dmidecode -t bios | grep "Release Date" | cut -d: -f2 | xargs)
echo -e "\n[BIOS Date]\n$bios"
# Handle MM/DD/YYYY or YYYY-MM-DD formats
bios_year=$(echo "$bios" | grep -oE "[0-9]{4}")

# --- RAM TYPE ---
ram_type=$(sudo dmidecode -t memory | grep -m1 "DDR" | xargs)
echo -e "\n[RAM Type]\n$ram_type"

# --- RAM SIZE (accurate via dmidecode) ---
echo -e "\n[RAM Modules]"
# Extract size and handle multiple lines
ram_modules=$(sudo dmidecode -t memory | grep -E "Size: [0-9]+ GB")
echo "$ram_modules"

# Calculate total RAM from modules
ram_total=0
if [[ -n "$ram_modules" ]]; then
  while read -r line; do
    size=$(echo "$line" | grep -oE "[0-9]+" | head -n1)
    if [[ -n "$size" ]]; then
      ram_total=$((ram_total + size))
    fi
  done <<< "$ram_modules"
fi

# fallback if dmidecode fails
if [[ "$ram_total" -eq 0 ]]; then
  ram_total=$(free -g | awk '/^Mem:/{print $2}')
  ram_source="(fallback from OS)"
else
  ram_source="(from dmidecode)"
fi

echo -e "\n[Total RAM]\n${ram_total} GB $ram_source"

# --- STORAGE ---
echo -e "\n[Storage Devices]"
total_storage=0

lsblk -d -o NAME,SIZE,ROTA,TYPE | grep disk | while read name size rota type; do
  if [[ "$name" == nvme* ]]; then
    dtype="NVMe ⚡"
  elif [[ "$rota" == "0" ]]; then
    dtype="SSD"
  else
    dtype="HDD"
  fi
  echo "/dev/$name - $size ($dtype)"
done

# --- AGE ---
current_year=$(date +%Y)

if [[ "$release_year" != "Unknown" ]]; then
  age=$((current_year - release_year))
  source="CPU generation"
elif [[ -n "$bios_year" ]]; then
  age=$((current_year - bios_year))
  source="BIOS date"
else
  age=0
  source="Unknown (could not determine)"
fi

echo -e "\n=== Final Estimate ==="
echo "Estimated Age: ~$age years"
echo "Based on: $source"

# --- VERDICT ---
if (( age <= 3 )); then
  verdict="Modern ✅"
elif (( age <= 6 )); then
  verdict="Decent 👍"
elif (( age <= 10 )); then
  verdict="Old but usable ⚠️"
else
  verdict="Very old ❌"
fi

echo "Verdict: $verdict"

# --- SMART INSIGHTS ---
echo -e "\n=== Smart Insights ==="

if (( ram_total >= 128 )); then
  echo "🔥 High RAM system detected"
  echo "💡 Good for virtualization / in-memory workloads"
fi

if lsblk | grep -q nvme; then
  echo "⚡ NVMe storage detected (fast I/O)"
fi

if (( age >= 8 )); then
  echo "⚠️ Older CPU – watch power efficiency"
fi

# --- VALUE ESTIMATE ---
echo -e "\n=== Rough Value Estimate ==="

if (( ram_total >= 256 )); then
  echo '💰 Estimated value: $500–700'
elif (( ram_total >= 128 )); then
  echo '💰 Estimated value: $300–500'
else
  echo '💰 Estimated value: <$300'
fi
