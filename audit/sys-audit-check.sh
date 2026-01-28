#!/usr/bin/env bash

# =========================================================================================================================
# Script Name: sys-audit-check.sh
# Version:     1.4.1
# Description: Professional system health audit with Thermal Monitoring,
#              file integrity checks, network audit and log rotation for K'aatech infrastructure.
# License:     MIT
# =========================================================================================================================

# Safety Settings
set -euo pipefail

# Environment Variables and Constants
declare -r VERSION="1.4.1"
declare -ri THRESHOLD_DISK=90
declare -ri THRESHOLD_RAM=80
declare -ri THRESHOLD_TEMP=75 # Celsius
declare -r  THRESHOLD_IOWAIT="5.0" # Max % of CPU waiting for I/O
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
    # Added 'ss' for network and 'iostat' (from sysstat) if available, or fallback to 'top'
    declare -a deps=(awk sed grep ps df free uptime sensors ss top)
    for bin in "${deps[@]}"; do
        if ! command -v "$bin" >/dev/null 2>&1; then
            if [[ "$bin" == "sensors" ]]; then
                # Interactive installation only if running in a terminal
                if [[ -t 0 ]]; then
                    read -p "[PROMPT] 'sensors' missing. Install lm-sensors? (y/N): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        apt-get update && apt-get install -y lm-sensors && sensors-detect --auto >/dev/null 2>&1 || true
                    else
                        log_msg "WARN" "Skipping thermal checks as requested."
                        return 0
                    fi
                else
                    log_msg "WARN" "Non-interactive shell: skipping 'sensors' installation."
                    return 0
                fi
            else
                log_msg "ERROR" "Critical dependency missing: $bin"
                exit 1
            fi
        fi
    done
    log_msg "INFO" "All dependencies resolved successfully."
}

check_cpu_performance() {
    # Extract 1m, 5m, and 15m load averages
    local load
    load=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ //')
    log_msg "INFO" "CPU Load Average (1m, 5m, 15m): $load"

    # I/O Wait detection using 'top' (standard on all Linux) with awk fallback (no bc needed)
    local iowait
    iowait=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* wa.*/\1/" | awk '{print $1}')
    log_msg "INFO" "CPU I/O Wait: ${iowait}%"

    # Floating point comparison using awk
    if awk "BEGIN {exit !($iowait > $THRESHOLD_IOWAIT)}"; then
        log_msg "WARN" "High I/O Wait detected! Disk latency is impacting CPU."
    fi

    if (( $(echo "$iowait > $THRESHOLD_IOWAIT" | bc -l) )); then
        log_msg "WARN" "High I/O Wait detected! Disk bottleneck suspected."
    fi

    log_msg "INFO" "Top 3 CPU consuming processes:"
    ps -eo pcpu,comm --sort=-pcpu | awk 'NR>1 && NR<=4 {printf "      - %s: %s%%\n", $2, $1}'
}

check_network_security() {
    log_msg "INFO" "Auditing open network ports (Listening)..."
    local open_ports
    open_ports=$(ss -tuln | awk 'NR>1 {printf "      - %s %s\n", $1, $4}' || true)

    if [[ -n "$open_ports" ]]; then
        echo "$open_ports"
    else
        log_msg "INFO" "No open listening ports detected (System is isolated)."
    fi
}

check_ram_usage() {
    local -i total used usage
    # Extracting data from free in a single pass of awk
    eval "$(free -m | awk '/Mem:/ {printf "total=%d; used=%d", $2, $3}')"
    usage=$(( used * 100 / total ))
    log_msg "INFO" "RAM Usage: ${usage}% (${used}MB / ${total}MB)"

    if [[ $usage -ge $THRESHOLD_RAM ]]; then
        log_msg "WARN" "High RAM consumption detected!"
    fi
}

check_disk_usage() {
    log_msg "INFO" "Scanning disk usage on all mounted partitions..."
    local -i found_issue=0
    while read -r pcent target; do
        local -i usage
        usage=${pcent%\%}
        if [[ $usage -ge $THRESHOLD_DISK ]]; then
            log_msg "WARN" "Disk space critical: ${usage}% on ${target}"
            found_issue=1
        fi
    done < <(df -h --output=pcent,target | tail -n +2)

    if [[ $found_issue -eq 0 ]]; then
        log_msg "INFO" "Disk usage within normal parameters."
    fi
}

check_zombie_processes() {
    log_msg "INFO" "Checking for zombie processes..."
    local zombies_list
    zombies_list=$(ps -eo pid,ppid,state,comm | awk '$3=="Z"' || true)

    if [[ -n "$zombies_list" ]]; then
        local -i count
        count=$(echo "$zombies_list" | wc -l)
        log_msg "WARN" "Detected $count zombie process(es):"

        # New: Detailed parent info
        while read -r z_pid z_ppid z_state z_cmd; do
            local p_name
            p_name=$(ps -p "$z_ppid" -o comm= || echo "unknown")
            log_msg "WARN" "      - Zombie PID: $z_pid | Parent: $p_name (PPID: $z_ppid) | CMD: $z_cmd"
        done <<< "$zombies_list"

        log_msg "INFO" "Action: Send SIGCHLD or SIGHUP to the parent process."
        #echo "$zombies_list" | awk '{printf "      - PID: %s (PPID: %s) CMD: %s\n", $1, $2, $4}'
        #log_msg "INFO" "Action: Kill parent PID using 'kill -HUP <PPID>'"
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
        cpu_temp=${cpu_out%.*}
        log_msg "INFO" "CPU Temperature: ${cpu_temp}°C"
        if [[ $cpu_temp -ge $THRESHOLD_TEMP ]]; then
            log_msg "WARN" "High CPU temperature detected!"
        fi
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
        if [[ ! -f "$file" ]]; then
            log_msg "CRITICAL" "File $file missing!"
            issues+=1
            continue
        fi
        # Detect world-writable via octal check
        if stat -c "%a" "$file" | grep -E '. . [2367]' >/dev/null 2>&1; then
             log_msg "CRITICAL" "Security risk: $file is WORLD-WRITABLE!"
             issues+=1
        fi
    done

    if [[ $issues -eq 0 ]]; then
        log_msg "INFO" "Critical files integrity verified (No world-writable bits)."
    fi
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
    check_network_security
    check_cpu_performance
    check_ram_usage
    check_disk_usage
    check_zombie_processes
    check_thermal_status

    log_msg "INFO" "------------------------------------------"
    log_msg "INFO" "Audit process finished successfully."
}

# Execution
main "$@"
