#!/bin/bash

# Application Health Checker
# Checks application uptime and status via HTTP

# Configuration
APP_URL="${1:-http://localhost:8080}"
LOG_FILE="./app-health.log"
STATUS_FILE="./app-status.dat"
TIMEOUT=10
MAX_RETRIES=3
RETRY_DELAY=2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to calculate uptime
calculate_uptime() {
    if [ -f "$STATUS_FILE" ]; then
        last_up=$(cat "$STATUS_FILE")
        current_time=$(date +%s)
        uptime_seconds=$((current_time - last_up))
        
        days=$((uptime_seconds / 86400))
        hours=$(((uptime_seconds % 86400) / 3600))
        minutes=$(((uptime_seconds % 3600) / 60))
        
        echo "${days}d ${hours}h ${minutes}m"
    else
        echo "Unknown"
    fi
}

# Function to update status file
update_status() {
    local status=$1
    if [ "$status" == "up" ]; then
        if [ ! -f "$STATUS_FILE" ]; then
            date +%s > "$STATUS_FILE"
            log_message "Application came UP - starting uptime tracking"
        fi
    else
        if [ -f "$STATUS_FILE" ]; then
            rm -f "$STATUS_FILE"
            log_message "Application went DOWN - uptime tracking reset"
        fi
    fi
}

# Function to check application health with retries
check_application() {
    local url=$1
    local attempt=1
    
    while [ $attempt -le $MAX_RETRIES ]; do
        # Perform HTTP request
        response=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}|%{size_download}" \
                   --connect-timeout $TIMEOUT \
                   --max-time $((TIMEOUT + 5)) \
                   "$url" 2>&1)
        
        # Parse response
        http_code=$(echo "$response" | cut -d'|' -f1)
        response_time=$(echo "$response" | cut -d'|' -f2)
        size=$(echo "$response" | cut -d'|' -f3)
        
        # Check if we got a valid response
        if [[ "$http_code" =~ ^[0-9]+$ ]]; then
            break
        fi
        
        if [ $attempt -lt $MAX_RETRIES ]; then
            echo -e "${YELLOW}Retry $attempt/$MAX_RETRIES failed, waiting ${RETRY_DELAY}s...${NC}"
            log_message "Attempt $attempt failed, retrying..."
            sleep $RETRY_DELAY
        fi
        
        attempt=$((attempt + 1))
    done
    
    # Analyze HTTP status code
    if [[ ! "$http_code" =~ ^[0-9]+$ ]]; then
        # Connection failed completely
        echo -e "${RED}✗ Application is DOWN${NC}"
        echo -e "  Status: Connection Failed"
        echo -e "  Error: Unable to reach the application"
        echo -e "  Attempts: $MAX_RETRIES"
        log_message "CRITICAL - Application DOWN | Connection failed after $MAX_RETRIES attempts"
        update_status "down"
        return 1
        
    elif [ "$http_code" -eq 200 ]; then
        # Success
        uptime=$(calculate_uptime)
        echo -e "${GREEN}✓ Application is UP${NC}"
        echo -e "  Status Code: ${GREEN}$http_code${NC}"
        echo -e "  Response Time: ${response_time}s"
        echo -e "  Content Size: ${size} bytes"
        echo -e "  Uptime: ${BLUE}${uptime}${NC}"
        log_message "SUCCESS - Application UP | Status: $http_code | Response: ${response_time}s | Size: ${size}B"
        update_status "up"
        return 0
        
    elif [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        # 2xx success codes
        uptime=$(calculate_uptime)
        echo -e "${GREEN}✓ Application is UP${NC}"
        echo -e "  Status Code: ${GREEN}$http_code${NC} (Success)"
        echo -e "  Response Time: ${response_time}s"
        echo -e "  Uptime: ${BLUE}${uptime}${NC}"
        log_message "SUCCESS - Application UP | Status: $http_code | Response: ${response_time}s"
        update_status "up"
        return 0
        
    elif [ "$http_code" -ge 300 ] && [ "$http_code" -lt 400 ]; then
        # Redirects - consider as up but log
        uptime=$(calculate_uptime)
        echo -e "${YELLOW}→ Application is UP (Redirect)${NC}"
        echo -e "  Status Code: ${YELLOW}$http_code${NC}"
        echo -e "  Response Time: ${response_time}s"
        echo -e "  Uptime: ${BLUE}${uptime}${NC}"
        log_message "WARNING - Application UP with redirect | Status: $http_code"
        update_status "up"
        return 0
        
    elif [ "$http_code" -ge 400 ] && [ "$http_code" -lt 500 ]; then
        # Client errors
        echo -e "${YELLOW}⚠ Application is UP but returned client error${NC}"
        echo -e "  Status Code: ${YELLOW}$http_code${NC} (Client Error)"
        echo -e "  Response Time: ${response_time}s"
        log_message "WARNING - Application responded with client error | Status: $http_code"
        update_status "up"
        return 2
        
    elif [ "$http_code" -ge 500 ]; then
        # Server errors - application is having issues
        echo -e "${RED}✗ Application is DOWN (Server Error)${NC}"
        echo -e "  Status Code: ${RED}$http_code${NC}"
        echo -e "  Response Time: ${response_time}s"
        echo -e "  Error: Internal server error"
        log_message "CRITICAL - Application DOWN | Status: $http_code (Server Error)"
        update_status "down"
        return 1
        
    else
        # Unknown status
        echo -e "${YELLOW}? Unknown Application Status${NC}"
        echo -e "  Status Code: $http_code"
        echo -e "  Response Time: ${response_time}s"
        log_message "UNKNOWN - Unexpected response | Status: $http_code"
        update_status "down"
        return 3
    fi
}

# Main script execution
echo "=========================================="
echo "   Application Health Checker"
echo "=========================================="
echo ""
echo "Target URL: $APP_URL"
echo "Timeout: ${TIMEOUT}s"
echo "Max Retries: $MAX_RETRIES"
echo ""
echo "Checking application status..."
echo ""

# Perform health check
check_application "$APP_URL"
exit_code=$?

echo ""
echo "=========================================="
echo "Log file: $LOG_FILE"
echo "=========================================="

exit $exit_code
