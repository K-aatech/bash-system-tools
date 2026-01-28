#!/usr/bin/env bash

# =========================================================================================================================
# Script Name: sys-audit-check.sh
# Version:     1.3.1
# Description: Professional system health audit with Thermal Monitoring,
#              file integrity checks and log rotation for K'aatech infrastructure.
# License:     MIT
# =========================================================================================================================

# Safety Settings
set -euo pipefail

# Environment Variables and Constants
declare -r VERSION="1.3.1"
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
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    printf "[%s] [%s] %s\n" "$timestamp" "$level" "$*" | tee -a "$LOG_FILE"
}

check_dependencies() {
    log_msg "INFO" "Validating system dependencies..."
    local bin
    declare -a deps=(awk sed grep ps df free uptime sensors)
    for bin in "${deps[@]}"; do
        if ! command -v "$bin" >/dev/null 2>&1; then
            if [[ "$bin" == "sensors" ]]; then
                log_msg "WARN" "Binary 'sensors' missing. Attempting installation..."
                apt-get update && apt-get install -y lm-sensors && sensors-detect --auto >/dev/null 2>&1 || true
            else
                printf "[ERROR] Critical dependency missing: %s\n" "$bin" >&2
                exit 1
            fi
        fi
    done
    log_msg "INFO" "All dependencies resolved successfully."
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
    local found_issue=0
    # Process line by line to ensure output visibility
    while read -r pcent target; do
        local -i usage
        usage=${pcent%\%}
        if [[ $usage -ge $THRESHOLD_DISK ]]; then
            log_msg "WARN" "Disk space critical: ${usage}% on ${target}"
            found_issue=1
        fi
    done < <(df -h --output=pcent,target | tail -n +2)

    [[ $found_issue -eq 0 ]] && log_msg "INFO" "Disk usage within normal parameters."
}

check_zombie_processes() {
    log_msg "INFO" "Checking for zombie processes..."
    local zombies_list
    zombies_list=$(ps -eo pid,ppid,state,comm | awk '$3=="Z"' || true)

    if [[ -n "$zombies_list" ]]; then
        local -i count
        count=$(echo "$zombies_list" | wc -l)
        log_msg "WARN" "Detected $count zombie processes:"
        echo "$zombies_list" | awk '{printf "      - PID: %s (Parent PID: %s) CMD: %s\n", $1, $2, $4}'
        log_msg "INFO" "Action: Kill parent PID using 'kill -HUP <PPID>'"
    else
        log_msg "INFO" "No zombie processes detected."
    fi
}

check_thermal_status() {
    log_msg "INFO" "Checking thermal and fan status..."
    # Extract CPU Temperature (common patterns: 'Package id 0' or 'Core 0')
    local cpu_out
    cpu_out=$(sensors 2>/dev/null | awk '/(Composite|Package id 0|Core 0)/ {print $4; exit}' | tr -d '+°C' || true)

    if [[ -n "$cpu_out" ]]; then
        local -i cpu_temp
        cpu_temp=${cpu_out%.*} # Remove decimal for integer comparison
        log_msg "INFO" "CPU Temperature: ${cpu_temp}°C"
        [[ $cpu_temp -ge $THRESHOLD_TEMP ]] && log_msg "WARN" "High CPU temperature detected!"
    else
        log_msg "WARN" "Thermal sensors not reporting data."
    fi

    # Check Fans
    local fans
    fans=$(sensors 2>/dev/null | grep -i 'fan' | awk '$2 > 0 {printf "      - %s: %s %s\n", $1, $2, $3}' || true)
    if [[ -n "$fans" ]]; then
        log_msg "INFO" "Active Fans detected:\n$fans"
    else
        log_msg "INFO" "No active fans detected or not supported."
    fi
}

check_file_integrity() {
    log_msg "INFO" "Checking critical file permissions..."
    declare -a critical_files=("/etc/passwd" "/etc/shadow" "/etc/sudoers")
    local -i issues=0

    for file in "${critical_files[@]}"; do
        [[ ! -f "$file" ]] && { log_msg "CRITICAL" "File $file missing!"; issues+=1; continue; }

        # Detect world-writable via octal check
        if stat -c "%a" "$file" | grep -E '. . [2367]' >/dev/null 2>&1; then
             log_msg "CRITICAL" "Security risk: $file is WORLD-WRITABLE!"
             issues+=1
        fi
    done
    [[ $issues -eq 0 ]] && log_msg "INFO" "Critical files integrity verified (No world-writable bits)."
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

    log_msg "INFO" "------------------------------------------"
    log_msg "INFO" "Audit process finished successfully."
}

# Execution
main "$@"
