#!/usr/bin/env bash
# ==============================================================================
# Script Name:  system-health-audit.sh
# Description:  Professional system health audit for K'aatech infrastructure.
# Includes:     Dependency checks, log rotation, file integrity, thermal monitoring and Performance Audit.
# Standards:    GBSG Compliant | K'aatech Baseline v1.1.0
# License:      MIT
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Environment & Globals ---
# x-release-please-version
SUITE_VERSION="0.1.0"
readonly SUITE_VERSION

THRESHOLD_DISK="${THRESHOLD_DISK:-90}"
THRESHOLD_RAM="${THRESHOLD_RAM:-80}"
THRESHOLD_TEMP="${THRESHOLD_TEMP:-75}"
THRESHOLD_IOWAIT="${THRESHOLD_IOWAIT:-5.0}"
# Core dependencies for audit functionality (GBSG compliant)
readonly CORE_DEPS=(awk sed grep df free uptime stat vmstat ps ip ss ping)
# Optional dependencies for enhanced reporting (GBSG compliant)
readonly OPTIONAL_DEPS=(sensors bc)

# --- Bootstrap ---
# Deterministic path calculation (Cross-platform compatible) with fail-fast logic
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
LIB_LOGGING="${SCRIPT_DIR}/../lib/logging.sh"
LIB_UTILS="${SCRIPT_DIR}/../lib/sys-utils.sh"
LIB_NET="${SCRIPT_DIR}/../lib/net-utils.sh"

# shellcheck source=../lib/logging.sh
[[ -f "${LIB_LOGGING}" ]] && source "${LIB_LOGGING}"
# shellcheck source=../lib/sys-utils.sh
[[ -f "${LIB_UTILS}" ]] && source "${LIB_UTILS}"
# shellcheck source=../lib/net-utils.sh
[[ -f "${LIB_NET}" ]] && source "${LIB_NET}"

# It allows overwriting from the environment, e.g.: log_dir=/var/log/custom ./script.sh
export log_dir="${log_dir:-./logs}"
LOG_FILE="${log_dir}/$(basename "$0" .sh).log"
export LOG_FILE
# Asegurar que el directorio de logs existe antes de iniciar
[[ ! -d "${log_dir}" ]] && mkdir -p "${log_dir}"

# --- Core Functions ---
audit_thermal_status() {
  command -v sensors > /dev/null 2>&1 || return 0

  local max_temp
  log_event "INFO" "Checking thermal status..."
  # Extracts the highest temperature from all adapters
  max_temp=$(sensors -A 2> /dev/null | grep '°C' | awk '{print $NF}' | grep -oP '\+\d+\.\d+' | tr -d '+' | sort -nr | head -n1 | cut -d. -f1)

  if [[ -n "${max_temp}" ]]; then
    log_event "INFO" "Max CPU Temperature: ${max_temp}°C"
    if [[ "${max_temp}" -ge "${THRESHOLD_TEMP}" ]]; then
      log_event "WARN" "High temperature detected!"
    fi
  fi
}

audit_cpu_performance() {
  local load_1m load_5m load_15m iowait
  log_event "INFO" "Auditing CPU performance..."

  # Capturing the three load averages (Resilient Parsing)
  IFS=' ' read -r load_1m load_5m load_15m < <(uptime | sed 's/.*load average: //' | tr -d ',')
  log_event "INFO" "CPU Load Average: [1m: ${load_1m}] [5m: ${load_5m}] [15m: ${load_15m}]"

  iowait=$(vmstat 1 2 | tail -1 | awk '{print $16}')
  log_event "INFO" "CPU I/O Wait: ${iowait}%"

  if awk "BEGIN {exit !($iowait > $THRESHOLD_IOWAIT)}"; then
    log_event "WARN" "High I/O Wait detected!"
  fi
}

audit_zombie_processes() {
  local zombies_list z_pid z_ppid z_state z_cmd p_name count
  log_event "INFO" "Checking for zombie processes..."

  # We obtain the list. We use a custom delimiter to avoid conflicts with the global IFS.
  zombies_list=$(ps -eo pid,ppid,state,comm | awk '$3=="Z" {print $1","$2","$3","$4}' || true)

  if [[ -n "${zombies_list}" ]]; then
    count=$(echo "${zombies_list}" | wc -l | xargs)
    log_event "WARN" "Detected ${count} zombie process(es):"

    # We changed IFS locally to parse the comma-delimited list
    while IFS=',' read -r z_pid z_ppid z_state z_cmd; do
      p_name=$(ps -p "${z_ppid}" -o comm= 2> /dev/null || echo "unknown")
      log_event "WARN" "  - PID: ${z_pid} [State: ${z_state}] | Parent: ${p_name} (${z_ppid}) | CMD: ${z_cmd}"
    done <<< "${zombies_list}"
    log_event "INFO" "Recommendation: Send SIGCHLD to parent processes."
  else
    log_event "OK" "No zombie processes detected."
  fi
}

audit_memory_usage() {
  local total used usage
  # Avoid SC2155 by separating declaration and assignment
  total=$(free -m | awk '/Mem:/ {print $2}')
  used=$(free -m | awk '/Mem:/ {print $3}')
  # Defensive check for division by zero or empty values
  if [[ -n "${total}" ]] && [[ "${total}" -gt 0 ]]; then
    usage=$((used * 100 / total))
    log_event "INFO" "RAM Usage: ${usage}% (${used}MB/${total}MB)"
    if [[ "${usage}" -ge "${THRESHOLD_RAM}" ]]; then
      log_event "WARN" "High RAM consumption!"
    fi
  else
    log_event "CRIT" "Could not determine RAM metrics."
  fi
}

audit_disk_health() {
  local usage target p_val
  local -i found_issue=0

  log_event "INFO" "Scanning disk partitions..."
  while read -r usage target; do
    p_val=$(echo "${usage}" | tr -d '%[:space:]')
    if [[ "$p_val" =~ ^[0-9]+$ ]]; then
      if [[ "$p_val" -ge "$THRESHOLD_DISK" ]]; then
        log_event "WARN" "Disk space critical: ${usage} on ${target}"
        found_issue=1
      fi
    fi
  done < <(df -h --output=pcent,target | tail -n +2)

  if [[ ${found_issue} -eq 0 ]]; then
    log_event "OK" "Disk usage normal."
  fi
}

# --- Main Execution ---
main() {
  # 1. Validation of Privileges (Security by Design)
  [[ "${EUID}" -ne 0 ]] && {
    log_event "CRIT" "Root privileges required for security baseline audit."
    exit 1
  }
  # 2. Dependency Check (Delegated)
  check_dependencies "${CORE_DEPS[@]}"
  # Optional (non-blocking) dependencies. Are not critical but enhance reporting
  local missing_opt=()
  for dep in "${OPTIONAL_DEPS[@]}"; do
    command -v "${dep}" > /dev/null 2>&1 || missing_opt+=("${dep}")
  done
  [[ ${#missing_opt[@]} -gt 0 ]] && log_event "WARN" "Optional tools missing: ${missing_opt[*]}"

  # 3. Initialization
  rotate_logs
  log_event "INFO" "Starting K'aatech System Health Audit v${SUITE_VERSION}"
  log_event "INFO" "-------------------------------------------------"
  # 4. Maintenance
  [[ -f /var/run/reboot-required ]] && log_event "WARN" "SYSTEM REBOOT REQUIRED (Security updates pending)"
  # 5. Security Audit (Delegated to sys-utils)
  log_event "INFO" "Auditing File Integrity..."
  audit_baseline_permissions || log_event "WARN" "Permission mismatches detected."
  # 6. Performance Audits
  audit_thermal_status
  audit_cpu_performance
  audit_zombie_processes
  audit_memory_usage
  audit_disk_health

  # 7. Network Audits (Delegated to net-utils)
  log_event "INFO" "--- NETWORK AUDIT ---"
  get_network_context || true
  get_dns_resolvers || true
  get_listening_ports

  if check_internet_connectivity; then
    check_multi_cloud_latency
  fi

  log_event "INFO" "-------------------------------------------------"
  log_event "OK" "Audit complete."
}

main "$@"
