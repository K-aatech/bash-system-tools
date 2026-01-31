#!/usr/bin/env bash
# =========================================================================================================================
# Script Name: logging.sh
# Version:     1.5.0
# Description: K'aatech Bash System Tools - Core Logging Library v1.5.0
# License:     MIT
# =========================================================================================================================
set -euo pipefail
# --- Smart Color Detection ---
# Only use ANSI colors if output is a terminal
if [[ -t 1 || -t 2 ]]; then
    readonly CLR_RESET='\033[0m'
    readonly CLR_BLUE='\033[34m'
    readonly CLR_YELLOW='\033[33m'
    readonly CLR_RED='\033[31m'
    readonly CLR_GREEN='\033[32m'
else
    readonly CLR_RESET=''
    readonly CLR_BLUE=''
    readonly CLR_YELLOW=''
    readonly CLR_RED=''
    readonly CLR_GREEN=''
fi
# Log file path with default
: "${LOG_FILE:=/var/log/kaatech_audit.log}"
export LOG_FILE

log_event() {
    local level="${1:-INFO}"
    local message="${2:-No message provided}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")
            echo -e "${CLR_BLUE}[INFO]${CLR_RESET} $timestamp - $message"
            ;;
        "OK")
            echo -e "${CLR_GREEN}[ OK ]${CLR_RESET} $timestamp - $message"
            ;;
        "WARN")
            # Redirect to stderr for warnings
            echo -e "${CLR_YELLOW}[WARN]${CLR_RESET} $timestamp - $message" >&2
            ;;
        "CRIT")
            # Redirect to stderr for critical errors
            echo -e "${CLR_RED}[CRIT]${CLR_RESET} $timestamp - $message" >&2
            ;;
    esac

    # Idempotent-friendly logging: check file writability before appending
    if [[ -w "$LOG_FILE" || -w "$(dirname "$LOG_FILE")" ]]; then
        echo "[$level] $timestamp - $message" >> "$LOG_FILE" 2>/dev/null || true
    fi
}
