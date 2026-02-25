#!/usr/bin/env bash
# ==============================================================================
# Script Name: logging.sh
# Description: K'aatech Bash System Tools - Core Logging Library
# Global Vars: LOG_FILE, MAX_LOG_FILES, CLR_*
# ==============================================================================

# Security and Portability
set -euo pipefail
IFS=$'\n\t'

# --- Color Configuration ---
# Only define colors if the output is a terminal (attribution to v1.1.0)
if [[ -t 2 ]]; then
  readonly CLR_RESET='\033[38;2;220;220;220m'
  readonly CLR_BLUE='\033[38;2;21;133;181m'
  readonly CLR_GREEN='\033[38;2;76;175;80m'
  readonly CLR_RED='\033[38;2;153;27;27m'
  readonly CLR_YELLOW='\033[38;2;251;202;4m'
  readonly CLR_OFF='\033[0m'
else
  readonly CLR_RESET=''
  readonly CLR_BLUE=''
  readonly CLR_GREEN=''
  readonly CLR_RED=''
  readonly CLR_YELLOW=''
  readonly CLR_OFF=''
fi

# Global variables with default values ​​(Governance)
# Readonly is used for post-initialization constants
LOG_FILE="${LOG_FILE:-/tmp/kaatech_report.log}"
MAX_LOG_FILES="${MAX_LOG_FILES:-5}"

log_event() {
  local level="${1:-INFO}"
  local message="${2:-No message provided}"
  local timestamp color label visual_signaling log_dir

  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case "${level^^}" in
    "INFO")
      color="${CLR_BLUE}"
      label="[INFO]"
      visual_signaling="ℹ️ "
      ;;
    "OK")
      color="${CLR_GREEN}"
      label="[ OK ]"
      visual_signaling="✅ "
      ;;
    "WARN")
      color="${CLR_YELLOW}"
      label="[WARN]"
      visual_signaling="⚠️ "
      ;;
    "CRIT")
      color="${CLR_RED}"
      label="[CRIT]"
      visual_signaling="🚨 "
      ;;
    *)
      color="${CLR_RESET}"
      label="[LOG ]"
      visual_signaling="📝 "
      ;;
  esac

  # Fallback: Disable emoji if not in terminal to avoid encoding issues in files/pipes
  [[ ${USE_EMOJI} -eq 0 ]] && visual_signaling=""

  # Output to stderr
  printf "%b%s%s%b %b%s - %s%b\n" \
    "${color}" "${visual_signaling}" "${label}" "${CLR_OFF}" \
    "${CLR_RESET}" "${timestamp}" "${message}" "${CLR_OFF}" >&2

  # Persistence with idempotency check
  log_dir=$(dirname "${LOG_FILE}")
  if [[ -w "${LOG_FILE}" || (! -f "${LOG_FILE}" && -w "${log_dir}") ]]; then
    printf "[%s] %s - %s\n" "${level^^}" "${timestamp}" "${message}" >> "${LOG_FILE}" 2> /dev/null || true
  fi
}

rotate_logs() {
  local log_dir i next
  log_dir=$(dirname "${LOG_FILE}")

  [[ ! -w "${log_dir}" ]] && return 0
  [[ ! -f "${LOG_FILE}" ]] && return 0

  # Delete the oldest log if it exists to prevent overflow
  [[ -f "${LOG_FILE}.${MAX_LOG_FILES}" ]] && rm -f "${LOG_FILE}.${MAX_LOG_FILES}"

  # Manual deterministic rotation
  for ((i = MAX_LOG_FILES - 1; i >= 1; i--)); do
    next=$((i + 1))
    if [[ -f "${LOG_FILE}.${i}" ]]; then
      mv -f "${LOG_FILE}.${i}" "${LOG_FILE}.${next}"
    fi
  done

  # Atomically move current to .1
  if [[ -f "${LOG_FILE}" ]]; then
    mv -f "${LOG_FILE}" "${LOG_FILE}.1"
  fi

  # Create new log with secure permissions from birth
  (umask 027 && touch "${LOG_FILE}")
}
