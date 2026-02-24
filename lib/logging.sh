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
LOG_FILE="${LOG_FILE:-/var/log/kaatech_report.log}"
MAX_LOG_FILES="${MAX_LOG_FILES:-5}"

log_event() {
  local level="${1:-INFO}"
  local message="${2:-No message provided}"
  local timestamp
  local color
  local label

  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case "${level^^}" in # Convert to uppercase for robustness
    "INFO")
      color="${CLR_BLUE}"
      label="[INFO]"
      ;;
    "OK")
      color="${CLR_GREEN}"
      label="[ OK ]"
      ;;
    "WARN")
      color="${CLR_YELLOW}"
      label="[WARN]"
      ;;
    "CRIT")
      color="${CLR_RED}"
      label="[CRIT]"
      ;;
    *)
      color="${CLR_RESET}"
      label="[LOG ]"
      ;;
  esac

  # All logging output goes to stderr (>&2) so as not to interfere with data pipes
  printf "%b%s%b %b%s - %s%b\n" \
    "${color}" "${label}" "${CLR_OFF}" \
    "${CLR_RESET}" "${timestamp}" "${message}" "${CLR_OFF}" >&2

  # Writing to file (Idempotence)
  local log_dir
  log_dir=$(dirname "${LOG_FILE}")
  if [[ -w "${LOG_FILE}" || -w "${log_dir}" ]]; then
    printf "[%s] %s - %s\n" "${level}" "${timestamp}" "${message}" >> "${LOG_FILE}" 2> /dev/null || true
  fi
}

rotate_logs() {
  local log_dir
  log_dir=$(dirname "${LOG_FILE}")

  # Validation of permissions and existence
  if [[ ! -f "${LOG_FILE}" ]]; then
    touch "${LOG_FILE}" 2> /dev/null || return 0
  fi

  if [[ ! -w "${log_dir}" ]]; then
    return 0
  fi

  # Manual rotation (Deterministic)
  local i
  for i in $(seq "$((MAX_LOG_FILES - 1))" -1 1); do
    if [[ -f "${LOG_FILE}.${i}" ]]; then
      mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i + 1))"
    fi
  done

  mv "${LOG_FILE}" "${LOG_FILE}.1"
  touch "${LOG_FILE}"
}
