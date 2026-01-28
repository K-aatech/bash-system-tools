#!/usr/bin/env bash

# =========================================================================================================================
# Script Name: sys-audit-check.sh
# Version:     1.3.0
# Description: Professional system health audit with Thermal Monitoring,
#              file integrity checks and log rotation for K'aatech infrastructure.
# License:     MIT
# =========================================================================================================================

# Safety Settings
set -euo pipefail

# Environment Variables and Constants
declare -r VERSION="1.3.0"
declare -ri THRESHOLD_DISK=90
declare -ri THRESHOLD_RAM=80
declare -ri THRESHOLD_TEMP=75 # Celsius
declare -r  LOG_FILE="/var/log/kaatech_audit.log"
declare -ri MAX_LOG_FILES=5

# --- Core Functions ---

rotate_logs() {
    # Check if log file exists and we have permissions
    if [[ -f "$LOG_FILE" ]]; then
        if [[ ! -w $(dirname "$LOG_FILE") ]]; then
            # Silent fallback to stderr if /var/log is not writable
            return
        fi

        # Manual rotation for independence from logrotate
        for i in $(seq $((MAX_LOG_FILES - 1)) -1 1); do
            [[ -f "${LOG_FILE}.$i" ]] && mv "${LOG_FILE}.$i" "${LOG_FILE}.$((i + 1))"
        done
        mv "$LOG_FILE" "${LOG_FILE}.1"
    fi
    touch "$LOG_FILE"
}

log_msg() {
    local level=$1
    shift
    local msg
    msg="[%s] [%s] %s\n"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    # Output to stdout/stderr
    printf "$msg" "$timestamp" "$level" "$*"

    # Persistent logging
    if [[ -w "$LOG_FILE" ]]; then
        printf "$msg" "$timestamp" "$level" "$*" >> "$LOG_FILE"
    fi
}

check_dependencies() {
    local bin
    declare -a deps=(awk sed grep ps df free uptime sensors)
    for bin in "${deps[@]}"; do
        if ! command -v "$bin" >/dev/null 2>&1; then
            if [[ "$bin" == "sensors" ]]; then
                log_msg "WARN" "Binary 'sensors' missing. Attempting to install..."
                sudo apt-get update && sudo apt-get install -y lm-sensors
                sudo sensors-detect --auto >/dev/null 2>&1
            else
                printf "[ERROR] Critical dependency missing: %s\n" "$bin" >&2
                exit 1
            fi
        fi
    done
}

check_cpu_load() {
    # Extract 1m, 5m, and 15m load averages
    local load
    load=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ //')
    log_msg "INFO" "CPU Load Average (1m, 5m, 15m): $load"

    # Get top 3 CPU consuming processes
    log_msg "INFO" "Top 3 CPU consuming processes:"
    ps -eo pcpu,comm --sort=-pcpu | awk 'NR>1 && NR<=4 {printf "      - %s: %s%%\n", $2, $1}'
}

check_ram_usage() {
    local -i total used usage
    # Extracting data from free in a single pass of awk
    eval "$(free -m | awk '/Mem:/ {printf "total=%d; used=%d", $2, $3}')"
    usage=$(( used * 100 / total ))

    log_msg "INFO" "RAM Usage: ${usage}% (${used}MB / ${total}MB)"

    [[ $usage -ge $THRESHOLD_RAM ]] && log_msg "WARN" "High RAM consumption detected!"
}

check_disk_usage() {
    log_msg "INFO" "Scanning disk usage on all mounted partitions..."
    df -h --output=pcent,target | tail -n +2 | while read -r pcent target; do
        local -i usage
        usage=${pcent%\%}
        [[ $usage -ge $THRESHOLD_DISK ]] && log_msg "WARN" "Disk space critical: ${usage}% on ${target}"
    done
}

check_zombie_processes() {
    local -i zombies
    zombies=$(ps -eo pid,ppid,state,comm | awk '$3=="Z"' || true)

    if [[ -n "$zombies" ]]; then
        local count
        count=$(echo "$zombies" | wc -l)
        log_msg "WARN" "Detected $count zombie processes:"
        echo "$zombies" | awk '{printf "      - PID: %s (Parent PID: %s) CMD: %s\n", $1, $2, $4}'
        log_msg "INFO" "Action: Kill parent PID using 'kill -HUP <PPID>'"
    else
        log_msg "INFO" "No zombie processes detected."
    fi
}

check_thermal_status() {
    log_msg "INFO" "Checking thermal and fan status..."
    # Extract CPU Temperature (common patterns: 'Package id 0' or 'Core 0')
    local -i cpu_temp
    # Robust parsing: searches for the first numeric value after a '+' in relevant lines
    cpu_temp=$(sensors | awk '/(Composite|Package id 0|Core 0)/ {print $4; exit}' | tr -d '+°C' | cut -d. -f1)

    if [[ -n "$cpu_temp" ]]; then
        log_msg "INFO" "CPU Temperature: ${cpu_temp}°C"
        [[ $cpu_temp -ge $THRESHOLD_TEMP ]] && log_msg "WARN" "High CPU temperature detected!"
    else
        log_msg "WARN" "Could not parse CPU temperature."
    fi

    # Check Fans
    local fans
    fans=$(sensors | grep -i 'fan' | awk '$2 > 0 {printf "      - %s: %s %s\n", $1, $2, $3}' || true)
    if [[ -n "$fans" ]]; then
        log_msg "INFO" "Active Fans detected:"
        echo "$fans"
    else
        log_msg "INFO" "No active fans detected or not supported by hardware."
    fi
}

check_file_integrity() {
    log_msg "INFO" "Checking critical file permissions..."
    declare -a critical_files=("/etc/passwd" "/etc/shadow" "/etc/sudoers")

    for file in "${critical_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_msg "CRITICAL" "File $file missing!"
            continue
        fi

        # Detect if sensitive files are world-writable
        if [[ $(stat -c "%a" "$file" | grep -E '. . [2367]') ]]; then
             log_msg "CRITICAL" "Security risk: $file is WORLD-WRITABLE!"
        fi
    done
}

# Main Execution Flow
main() {
    # Must be root for full integrity check and package installation
    if [[ $EUID -ne 0 ]]; then
        printf "[ERROR] This script must be run as root to perform audit and rotation.\n" >&2
        exit 1
    fi

    rotate_logs
    log_msg "INFO" "K'aatech System Audit Utility v$VERSION"
    log_msg "INFO" "------------------------------------------"

    check_dependencies
    check_file_integrity
    check_cpu_load
    check_ram_usage
    check_disk_usage
    check_zombie_processes
    check_thermal_status

    log_msg "INFO" "Audit process finished successfully."
}

# Execution
main "$@"
