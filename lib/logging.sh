#!/usr/bin/env bash
# =========================================================================================================================
# Script Name: logging.sh
# Version:     1.7.0-rc.1
# Description: K'aatech Bash System Tools - Core Logging Library v1.7.0
# License:     MIT
# =========================================================================================================================
set -euo pipefail
# --- Smart Color Detection ---
# Only use ANSI colors if output is a terminal
if [[ -t 1 || -t 2 ]]; then
    # Corporate color definitions (TrueColor)
    readonly CLR_RESET='\033[38;2;220;220;220m'  # #DCDCDC
    readonly CLR_BLUE='\033[38;2;21;133;181m'   # #1585B5
    readonly CLR_GREEN='\033[38;2;76;175;80m'   # #4CAF50
    readonly CLR_RED='\033[38;2;153;27;27m'     # #991B1B
    readonly CLR_YELLOW='\033[38;2;251;202;4m'  # #FBCA04
    # Close color codes with original reset
    readonly CLR_OFF='\033[0m'
else
    readonly CLR_RESET=''
    readonly CLR_BLUE=''
    readonly CLR_YELLOW=''
    readonly CLR_RED=''
    readonly CLR_GREEN=''
    readonly CLR_OFF=''
fi
# Log file path with default
: "${LOG_FILE:=/var/log/kaatech_report.log}"
: "${MAX_LOG_FILES:=5}"
export LOG_FILE
export MAX_LOG_FILES

log_event() {
    local level="${1:-INFO}"
    local message="${2:-No message provided}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")
            echo -e "${CLR_BLUE}[INFO]${CLR_OFF} ${CLR_RESET}$timestamp - $message${CLR_OFF}"
            ;;
        "OK")
            echo -e "${CLR_GREEN}[ OK ]${CLR_OFF} ${CLR_RESET}$timestamp - $message${CLR_OFF}"
            ;;
        "WARN")
            echo -e "${CLR_YELLOW}[WARN]${CLR_OFF} ${CLR_RESET}$timestamp - $message${CLR_OFF}" >&2
            ;;
        "CRIT")
            echo -e "${CLR_RED}[CRIT]${CLR_OFF} ${CLR_RESET}$timestamp - $message${CLR_OFF}" >&2
            ;;
    esac

    # Idempotent-friendly logging: check file writability before appending
    if [[ -w "$LOG_FILE" || -w "$(dirname "$LOG_FILE")" ]]; then
        echo "[$level] $timestamp - $message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

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
