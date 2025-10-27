#!/bin/bash
# System Health Monitoring Script
LOG_FILE="./system-health.log"
ALERT_LOG="./system-alerts.log"

# Thresholds
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80
PROC_THRESHOLD=300

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Add timestamp
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting System Health Monitor" | tee -a "$LOG_FILE"

# CPU Check - Alert if > 80%
cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
cpu_usage=$(echo "100 - $cpu_idle" | bc | cut -d. -f1)

if [ ! -z "$cpu_usage" ] && [ "$cpu_usage" -gt $CPU_THRESHOLD ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CPU Usage: ${cpu_usage}%" | tee -a "$LOG_FILE"
    echo -e "${RED}ALERT: High CPU usage detected: ${cpu_usage}% (> $CPU_THRESHOLD%)${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: High CPU usage detected: ${cpu_usage}% (> $CPU_THRESHOLD%)" >> "$ALERT_LOG"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CPU Usage: ${cpu_usage}% (Normal)" | tee -a "$LOG_FILE"
fi

# Memory Check - Alert if > 80%
memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')

if [ ! -z "$memory_usage" ] && [ "$memory_usage" -gt $MEM_THRESHOLD ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Memory Usage: ${memory_usage}%" | tee -a "$LOG_FILE"
    echo -e "${RED}ALERT: High memory usage detected: ${memory_usage}% (> $MEM_THRESHOLD%)${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: High memory usage detected: ${memory_usage}% (> $MEM_THRESHOLD%)" >> "$ALERT_LOG"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Memory Usage: ${memory_usage}% (Normal)" | tee -a "$LOG_FILE"
fi

# Disk Check - Alert if > 80%
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ ! -z "$disk_usage" ] && [ "$disk_usage" -gt $DISK_THRESHOLD ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Disk Usage: ${disk_usage}%" | tee -a "$LOG_FILE"
    echo -e "${RED}ALERT: High disk usage detected: ${disk_usage}% (> $DISK_THRESHOLD%)${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: High disk usage detected: ${disk_usage}% (> $DISK_THRESHOLD%)" >> "$ALERT_LOG"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Disk Usage: ${disk_usage}% (Normal)" | tee -a "$LOG_FILE"
fi

# Process Count Check - Alert if > 300
proc_count=$(ps -e --no-headers | wc -l)

if [ ! -z "$proc_count" ] && [ "$proc_count" -gt $PROC_THRESHOLD ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Process Count: ${proc_count}" | tee -a "$LOG_FILE"
    echo -e "${RED}ALERT: High process count detected: ${proc_count} (> $PROC_THRESHOLD)${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: High process count detected: ${proc_count} (> $PROC_THRESHOLD)" >> "$ALERT_LOG"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Process Count: ${proc_count} (Normal)" | tee -a "$LOG_FILE"
fi

# Critical Process Check
critical_processes=("systemd" "init")
for process in "${critical_processes[@]}"; do
    if ! pgrep "$process" > /dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Critical process not running: $process" | tee -a "$LOG_FILE"
        echo -e "${RED}ALERT: Critical process not running: $process${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERT: Critical process not running: $process" >> "$ALERT_LOG"
    fi
done

echo "$(date '+%Y-%m-%d %H:%M:%S') - System health check completed" | tee -a "$LOG_FILE"
echo "------" | tee -a "$LOG_FILE"
