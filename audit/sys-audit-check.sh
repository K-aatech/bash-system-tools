#!/usr/bin/env bash

# ==============================================================================
# Script: sys-audit-check.sh
# Description: Professional system health audit with Thermal Monitoring for K'aatech infrastructure.
# Style: K'aatech Engineering Guide v1.0
# ==============================================================================

# 1. Security & Safety (Style Guide Rule #1)
set -euo pipefail

# 2. Global Variables (Style Guide Rule #1 - Upper Case)
readonly VERSION="1.0.0"
readonly THRESHOLD_DISK=90
readonly THRESHOLD_RAM=80
readonly THRESHOLD_TEMP=75 # Celsius

# 3. Logging Function (Style Guide Rule #2 - stderr for errors)
log_msg() {
    local level=$1
    shift
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*"
}

# 4. Resource Checks
check_cpu_load() {
    # Extract 1m, 5m, and 15m load averages
    local load
    load=$(uptime | awk -F'load average:' '{ print $2 }' | xargs)
    log_msg "INFO" "CPU Load Average (1m, 5m, 15m): $load"

    # Get top 3 CPU consuming processes
    log_msg "INFO" "Top 3 CPU consuming processes:"
    ps -eo pcpu,comm --sort=-pcpu | head -n 4 | tail -n 3 | awk '{printf "      - %s: %s%%\n", $2, $1}'
}

check_ram_usage() {
    local total used free usage
    # Get memory in MB
    total=$(free -m | awk '/Mem:/ { print $2 }')
    used=$(free -m | awk '/Mem:/ { print $3 }')
    usage=$(( used * 100 / total ))

    log_msg "INFO" "RAM Usage: ${usage}% (${used}MB / ${total}MB)"

    if [ "$usage" -ge "$THRESHOLD_RAM" ]; then
        log_msg "WARN" "High RAM consumption detected!"
    fi
}

check_disk_usage() {
    log_msg "INFO" "Scanning disk usage on all mounted partitions..."
    df -h --output=pcent,target | tail -n +2 | while read -r output; do
        local usage
        usage=$(echo "$output" | awk '{print $1}' | sed 's/%//g')
        local mount
        mount=$(echo "$output" | awk '{print $2}')

            if [ "$usage" -ge "$THRESHOLD_DISK" ]; then
                log_msg "WARN" "Disk space critical: ${usage}% on ${mount}"
            fi
    done
}

check_zombie_processes() {
    local zombies
    zombies=$(ps aux | awk '{if ($8=="Z") print $2}' | wc -l)
    if [ "$zombies" -gt 0 ]; then
        log_msg "WARN" "Detected $zombies zombie processes!"
    else
        log_msg "INFO" "No zombie processes detected."
    fi
}

# 5. Thermal Monitoring
# 5.1. Check for dependencies
check_dependencies() {
    if ! command -v sensors >/dev/null 2>&1; then
        log_msg "WARN" "Package 'lm-sensors' not found. Thermal checks will be skipped."
        return 1
    fi
    return 0
}
# 5.2. Thermal Check Function
check_thermal_status() {
    log_msg "INFO" "Checking thermal and fan status..."

    # Extract CPU Temperature (common patterns: 'Package id 0' or 'Core 0')
    local cpu_temp
    cpu_temp=$(sensors | grep -E 'i380|Package|Core 0' | head -n 1 | awk '{print $4}' | sed 's/+//;s/°C//' | cut -d. -f1)

    if [[ -n "$cpu_temp" ]]; then
        log_msg "INFO" "CPU Temperature: ${cpu_temp}°C"
        if [ "$cpu_temp" -ge "$THRESHOLD_TEMP" ]; then
            log_msg "WARN" "High CPU temperature detected!"
        fi
    else
        log_msg "WARN" "Could not parse CPU temperature."
    fi

    # Check Fans
    local fans
    fans=$(sensors | grep -i 'fan' | awk '{print $2 " " $3}' || true)
    if [[ -z "$fans" ]]; then
        log_msg "INFO" "No fans detected or not supported by hardware."
    else
        echo "$fans" | while read -r fan_info; do
            log_msg "INFO" "Fan Speed: $fan_info"
        done
    fi
}

# 6. Main Execution Flow
main() {
    log_msg "INFO" "K'aatech System Audit Utility v$VERSION"
    log_msg "INFO" "------------------------------------------"

    check_cpu_load
    check_ram_usage
    check_disk_usage
    check_zombie_processes

    # Conditional Thermal Check
    if check_dependencies; then
        check_thermal_status
    fi

    log_msg "INFO" "Audit process finished successfully."
}

# Execution
main "$@"
