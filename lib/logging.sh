# shellcheck shell=bash
# ==============================================================================
# LIBRARY: logging.sh
# DESCRIPTION: Core logging engine with color support, persistence, and rotation.
# VERSION: 1.2.1
# STANDARDS: GBSG Compliant | K'aatech Baseline v1.2.1
# ==============================================================================

# Security and Portability
set -euo pipefail
IFS=$'\n\t'

# --- ENVIRONMENT GUARD ---

if [[ -z "${BASH_VERSINFO:-}" || "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  printf "[CRIT] This library requires Bash >= 4.x\n" >&2
  exit 1
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf "[CRIT] This file must be sourced, not executed.\n" >&2
  exit 1
fi

# --- CONFIGURATION & CONSTANTS ---

# Default persistence settings
KISA_LOG_FILE="${LOG_FILE:-/tmp/kaatech_report.log}"
KISA_MAX_LOGS="${MAX_LOG_FILES:-5}"

# Color Palette (TrueColor 24-bit)
if [[ -t 2 ]]; then
  readonly CLR_RESET='\033[38;2;220;220;220m'
  readonly CLR_BLUE='\033[38;2;21;133;181m'
  readonly CLR_GREEN='\033[38;2;76;175;80m'
  readonly CLR_RED='\033[38;2;153;27;27m'
  readonly CLR_YELLOW='\033[38;2;251;202;4m'
  readonly CLR_OFF='\033[0m'
  readonly USE_VISUAL=1
else
  readonly CLR_RESET=''
  readonly CLR_BLUE=''
  readonly CLR_GREEN=''
  readonly CLR_RED=''
  readonly CLR_YELLOW=''
  readonly CLR_OFF=''
  readonly USE_VISUAL=0
fi

# --- PUBLIC API ---

# @description Dispatches a formatted log event to stderr and persistent file.
# @param $1 Severity level (INFO, OK, WARN, CRIT).
# @param $2 Message string.
log_event() {
  local level="${1:-INFO}"
  local message="${2:-No message provided}"
  local timestamp color label visual_signaling target_dir
  # Persistence (Handling unbound variables gracefully)

  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  target_dir=$(dirname "${KISA_LOG_FILE}")

  case "${level^^}" in
    "INFO")
      color="${CLR_BLUE}"
      label="[INFO]"
      visual_signaling="ℹ️  "
      ;;
    "OK")
      color="${CLR_GREEN}"
      label="[ OK ]"
      visual_signaling="✅  "
      ;;
    "WARN")
      color="${CLR_YELLOW}"
      label="[WARN]"
      visual_signaling="⚠️  "
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
  [[ ${USE_VISUAL} -eq 0 ]] && visual_signaling=""

  # 1. Terminal Output (stderr)
  printf "%b%s%s%b %b%s - %b%b\n" \
    "${color}" "${visual_signaling}" "${label}" "${CLR_OFF}" \
    "${CLR_RESET}" "${timestamp}" "${message}" "${CLR_OFF}" >&2

  # 2. File Persistence (Sanitized) (We cleaned ANSI escape codes for the flat log file)
  if [[ -d "${target_dir}" && -w "${target_dir}" ]]; then
    local clean_msg
    # shellcheck disable=SC2001
    clean_msg=$(printf "%b" "${message}" | sed 's/\x1b\[[0-9;]*m//g')
    printf "[%s] %s - %s\n" "${level^^}" "${timestamp}" "${clean_msg}" >> "${KISA_LOG_FILE}" 2> /dev/null || true
  fi
}

# @description Manages deterministic log rotation to prevent disk exhaustion.
rotate_logs() {
  local log_dir i next
  log_dir=$(dirname "${KISA_LOG_FILE}")

  [[ ! -d "${log_dir}" || ! -w "${log_dir}" ]] && return 0
  [[ ! -f "${KISA_LOG_FILE}" ]] && return 0

  # Delete the oldest log if it exists to prevent overflow
  [[ -f "${KISA_LOG_FILE}.${KISA_MAX_LOGS}" ]] && rm -f "${KISA_LOG_FILE}.${KISA_MAX_LOGS}"

  # Manual deterministic rotation
  for ((i = KISA_MAX_LOGS - 1; i >= 1; i--)); do
    next=$((i + 1))
    if [[ -f "${KISA_LOG_FILE}.${i}" ]]; then
      mv -f "${KISA_LOG_FILE}.${i}" "${KISA_LOG_FILE}.${next}"
    fi
  done

  # Atomically move current to .1
  if [[ -f "${KISA_LOG_FILE}" ]]; then
    mv -f "${KISA_LOG_FILE}" "${KISA_LOG_FILE}.1"
  fi

  # Initialize new log with secure permissions (0640)
  (umask 027 && touch "${KISA_LOG_FILE}")
}
