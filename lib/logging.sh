#!/usr/bin/env bash
# =========================================================================================================================
# Script Name: logging.sh
# Version:     1.5.0
# Description: Core Logging Library for K'aatech Bash System Tools.
# License:     MIT
# =========================================================================================================================
set -euo pipefail
# Colores ANSI
readonly CLR_RESET='\033[0m'
readonly CLR_BLUE='\033[34m'
readonly CLR_YELLOW='\033[33m'
readonly CLR_RED='\033[31m'
readonly CLR_GREEN='\033[32m'
# Configuración de Log
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
