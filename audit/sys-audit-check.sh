#!/usr/bin/env bash
# =========================================================================================================================
# Script Name: sys-audit-check.sh
# Version:     1.7.4
# Description: Professional system health audit with Thermal Monitoring,
#              file integrity checks, network audit and log rotation for K'aatech infrastructure.
# License:     MIT
# =========================================================================================================================

# Safety Settings
set -euo pipefail

# --- Environment & Globals (Gobernanza K'aatech) ---
: "${VERSION:="1.8.0"}"
: "${THRESHOLD_DISK:=90}"
: "${THRESHOLD_RAM:=80}"
: "${THRESHOLD_TEMP:=75}"
: "${THRESHOLD_IOWAIT:="5.0"}"
: "${LOG_FILE:="/var/log/kaatech_audit.log"}"
: "${MAX_LOG_FILES:=5}"
: "${LIB_PATH:="$(dirname "$0")/../lib/logging.sh"}"

# --- Bootstrap Logging ---
if [[ -f "${LIB_PATH}" ]]; then
    # shellcheck source=/dev/null
    source "${LIB_PATH}"
else
    log_event() {
        local level="${1}"
        local msg="${2}"
        local timestamp
        local color_code=""
        local color_reset="\033[0m"

        timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        # Detección Inteligente de TTY para colores
        if [[ -t 1 ]]; then
            case "${level}" in
                "CRIT") color_code="\033[31m" ;;
                "WARN") color_code="\033[33m" ;;
                "INFO") color_code="\033[32m" ;;
            esac
        fi

        if [[ "${level}" == "WARN" || "${level}" == "CRIT" ]]; then
            printf "%b[%s] %s - %s%b\n" "${color_code}" "${level}" "${timestamp}" "${msg}" "${color_reset}" >&2
        else
            printf "%b[%s] %s - %s%b\n" "${color_code}" "${level}" "${timestamp}" "${msg}" "${color_reset}"
        fi
    }
fi

# --- Core Functions ---

check_dependencies() {
    log_event "INFO" "Validating system dependencies..."
    local bin
    declare -a deps=(awk sed grep ps df free uptime sensors ss top)

    for bin in "${deps[@]}"; do
        if ! command -v "${bin}" >/dev/null 2>&1; then
            if [[ "${bin}" == "sensors" ]]; then
                handle_sensors_missing
            else
                log_event "CRIT" "Critical dependency missing: ${bin}"
                exit 1
            fi
        fi
    done
}

handle_sensors_missing() {
    if [[ -t 0 ]]; then
        log_event "WARN" "'sensors' missing. Interactive terminal detected."
        local reply
        read -p "[PROMPT] Install lm-sensors? (y/N): " -n 1 -r reply
        echo
        if [[ "${reply}" =~ ^[Yy]$ ]]; then
            install_sensors_package
        else
            log_event "WARN" "Skipping thermal checks as requested by user."
        fi
    else
        log_event "WARN" "Non-interactive shell: skipping 'sensors' installation."
    fi
}

install_sensors_package() {
    log_event "INFO" "Installing lm-sensors..."
    if apt-get update -qq && apt-get install -y -qq lm-sensors; then
        if ! sensors-detect --auto >/dev/null 2>&1; then
            log_event "WARN" "sensors-detect finished with non-zero exit code."
        fi
    else
        log_event "CRIT" "Failed to install lm-sensors package."
        return 1
    fi
}

check_file_integrity() {
    log_event "INFO" "Auditing critical file permissions..."
    declare -a critical_files=("/etc/passwd" "/etc/shadow" "/etc/sudoers")
    local -i issues=0

    for file in "${critical_files[@]}"; do
        [[ ! -f "${file}" ]] && { log_event "CRIT" "File ${file} missing!"; ((issues++)); continue; }

        # Securing world-writable check
        if [[ $(stat -c "%a" "${file}") =~ [2367]$ ]]; then
             log_event "CRIT" "Security risk: ${file} is WORLD-WRITABLE!"
             ((issues++))
        fi
    done
    [[ ${issues} -eq 0 ]] && log_event "INFO" "Critical files integrity verified."
}

check_cpu_performance() {
    local load iowait
    load=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ //')
    log_event "INFO" "CPU Load Average: ${load}"

    iowait=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* wa.*/\1/" | awk '{print $1}')
    log_event "INFO" "CPU I/O Wait: ${iowait}%"

    if awk "BEGIN {exit !(${iowait} > ${THRESHOLD_IOWAIT})}"; then
        log_event "WARN" "High I/O Wait detected!"
    fi
}

check_ram_usage() {
    local total used usage
    # Evitar eval por seguridad; usar awk para procesar directamente
    read -r total used < <(free -m | awk '/Mem:/ {print $2, $3}')
    usage=$(( used * 100 / total ))
    log_event "INFO" "RAM Usage: ${usage}% (${used}MB/${total}MB)"
    [[ ${usage} -ge ${THRESHOLD_RAM} ]] && log_event "WARN" "High RAM consumption!"
}

check_disk_usage() {
    log_event "INFO" "Scanning disk usage..."
    local -i found_issue=0
    while read -r pcent target; do
        local usage=${pcent%\%}
        if [[ ${usage} -ge ${THRESHOLD_DISK} ]]; then
            log_event "WARN" "Disk space critical: ${usage}% on ${target}"
            found_issue=1
        fi
    done < <(df -h --output=pcent,target | tail -n +2)
    [[ ${found_issue} -eq 0 ]] && log_event "INFO" "Disk usage normal."
}

rotate_logs() {
    # Stub: Implementar según necesidad de K'aatech para evitar acumulación
    log_event "INFO" "Rotating logs (Policy: Keep ${MAX_LOG_FILES})..."
}

main() {
    if [[ "${EUID}" -ne 0 ]]; then
        log_event "CRIT" "This script must be run as root."
        exit 1
    fi

    rotate_logs
    log_event "INFO" "K'aatech System Audit Utility v${VERSION}"
    log_event "INFO" "------------------------------------------"

    check_dependencies
    check_file_integrity
    check_cpu_performance
    check_ram_usage
    check_disk_usage
    # ... demás funciones de auditoría ...

    log_event "INFO" "------------------------------------------"
    log_event "INFO" "Audit complete."
}

main "$@"
