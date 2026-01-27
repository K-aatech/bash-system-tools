#!/usr/bin/env bash

# ==============================================================================
# Script: sys-audit-check.sh
# Description: Professional system health audit for K'aatech infrastructure.
# Style: K'aatech Engineering Guide v1.0
# ==============================================================================

# 1. Security & Safety (Style Guide Rule #1)
set -euo pipefail

# 2. Global Variables (Style Guide Rule #1 - Upper Case)
readonly VERSION="1.0.0"
readonly THRESHOLD=90

# 3. Logging Function (Style Guide Rule #2 - stderr for errors)
log_msg() {
    local level=$1
    shift
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*"
}

# 4. Resource Checks (The "Trap" is here)
check_disk_usage() {
    log_msg "INFO" "Scanning disk usage on all mounted partitions..."

    # We use a temp file to demonstrate cleanup later
    local tmp_file="/tmp/disk_report.txt"
    df -h > "$tmp_file"

    while read -r line; do
        # --- THE CONTROL TRAP (SC2086) ---
        # The variable $line is used without double quotes below.
        # This will trigger the ShellCheck error.
        local usage
        usage=$(echo $line | awk '{print $5}' | sed 's/%//g')

        if [[ "$usage" =~ ^[0-9]+$ ]]; then
            if [ "$usage" -ge "$THRESHOLD" ]; then
                log_msg "WARN" "Critical usage detected: $usage% on $(echo $line | awk '{print $6}')"
            fi
        fi
    done < <(tail -n +2 "$tmp_file")

    # Clean up temp file (Style Guide Rule #2C)
    rm -f "$tmp_file"
}

check_cpu_load() {
    local load
    load=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
    log_msg "INFO" "Current CPU Load Average (1m): $load"
}

# 5. Main Execution Flow
main() {
    log_msg "INFO" "K'aatech System Audit Utility v$VERSION"
    log_msg "INFO" "------------------------------------------"

    check_cpu_load
    check_disk_usage

    log_msg "INFO" "Audit process finished successfully."
}

# Execution
main "$@"
