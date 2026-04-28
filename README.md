# My Server Utils

A collection of lightweight Bash scripts for server monitoring, security auditing, and automated maintenance.

## Scripts Overview

### 1. `security_audit.sh`
Performs an incident investigation and security audit.
- Checks for suspicious logins on specific dates.
- Monitors SSH successful logins and sudo activity.
- Searches for potential crypto-mining files (e.g., `xmrig`).
- Audits user bash history for suspicious commands.

### 2. `resources.sh`
Monitor server resources in real-time.
- Lists top processes by CPU and Memory.
- Shows system load and Docker container stats.
- Identifies heavy directories and open network connections.

### 3. `check_server_age.sh`
Estimates the physical age of the server hardware.
- Identifies CPU generation and release year.
- Checks BIOS release date.
- Summarizes RAM capacity and storage types (SSD/HDD/NVMe).
- Provides a "verdict" on hardware modernity.

### 4. `backup_manager.sh`
Automates local directory backups.
- Creates compressed `.tar.gz` archives.
- Implements retention-based rotation (removes old backups).

### 5. `network_health.sh`
Verifies network connectivity and latency.
- Pings common DNS (8.8.8.8).
- Checks HTTP status codes for specific endpoints using `curl`.

### 6. `user_activity_monitor.sh`
Audits active user sessions.
- Lists currently logged-in users and their active processes.
- Alerts on unauthorized or non-standard user activity.

### 7. `db_health_check.sh`
Monitors database service status.
- Supports PostgreSQL, MySQL, Redis, and MongoDB.
- Checks if services are active and reports resource usage.

### 8. `log_cleaner.sh`
Optimizes storage by managing log files.
- Identifies large log files in `/var/log`.
- Purges old compressed log archives (`.gz`).

### 9. `ssl_expiry_check.sh`
Monitors SSL certificate expiration dates.
- Uses `openssl` to check certificates for specified domains.
- Warns if certificates are close to expiry.

### 10. `system_update_notifier.sh`
Tracks pending OS security updates.
- Supports APT (Debian/Ubuntu) and YUM (RHEL/CentOS).
- Reports the number of packages awaiting updates.

## Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/youruser/my_server_utils.git
   cd my_server_utils
   ```

2. **Make scripts executable (if needed):**
   ```bash
   chmod +x *.sh
   ```

3. **Run a script:**
   ```bash
   ./resources.sh
   ```
   *Note: Some scripts (like `security_audit.sh` or `check_server_age.sh`) may require `sudo` privileges to access system logs or hardware info.*

## Requirements
- Most scripts are designed for **Linux** environments.
- Common utilities required: `grep`, `awk`, `sed`, `curl`, `openssl`, `dmidecode` (for hardware info).
