# shellcheck shell=bash
# ==============================================================================
# Script Name:  net-utils.sh
# This file is intended to be sourced, not executed directly.
# Description:  K'aatech Network Audit Library - "Fierro-to-Cloud" Perspective.
# Standards:    GBSG Compliant | K'aatech Baseline v1.1.0
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# Fallback logging (Dependency check)
if ! command -v log_event > /dev/null 2>&1; then
  log_event() { printf "[%s] %s\n" "${1}" "${*:2}" >&2; }
fi

# --- Block 1: Local Context (Discovery) ---

fetch_network_metadata() {
  # shellcheck disable=SC2034
  KISA_IFACE=$(ip route get 8.8.8.8 2> /dev/null | awk '/dev/ {print $5}' | head -n1)

  if [[ -n "${KISA_IFACE}" ]]; then
    # shellcheck disable=SC2034
    KISA_PRIMARY_IP=$(ip -4 addr show "${KISA_IFACE}" | awk '/inet / {print $2}' | cut -d/ -f1)
    # shellcheck disable=SC2034
    KISA_NETMASK=$(ip -4 addr show "${KISA_IFACE}" | awk '/inet / {print $2}' | cut -d/ -f2)
    # shellcheck disable=SC2034
    KISA_GW=$(ip route show default dev "${KISA_IFACE}" | awk '{print $3}' | head -n1)
    [[ -z "${KISA_GW}" ]] && KISA_GW=$(ip route | awk '/default/ {print $3}' | head -n1)
  fi
}

fetch_dns_metadata() {
  # shellcheck disable=SC2034
  KISA_DNS=$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}' | xargs)
}

# --- Block 2: Vitality (Action-Oriented) ---

check_internet_connectivity() {
  log_event "INFO" "Checking internet connectivity (Target: 8.8.8.8)..."
  if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    log_event "OK" "Internet access verified."
    return 0
  else
    log_event "CRIT" "No internet access detected."
    return 1
  fi
}

# --- Block 3: LMetrics (Action-Oriented / Reports) ---

audit_listening_ports() {
  log_event "INFO" "Auditing Open and Active Ports (LISTEN)..."

  # GBSG: Use ss (iproute2) as it is the modern standard for socket statistics, providing more accurate and detailed information than netstat.
  if ! command -v ss > /dev/null 2>&1; then
    log_event "WARN" "ss command not found. Skipping port audit."
    return 0
  fi

  # Capture TCP/UDP ports in LISTEN state
  # Format: Protocol | Port | Service/Process
  log_event "INFO" "Port Mapping (TCP/UDP LISTEN):"
  ss -tunlpH | awk '{printf "  - %-5s %-10s %-20s\n", $1, $5, $7}' | while read -r line; do
    log_event "INFO" "${line}"
  done
}

audit_multi_cloud_latency() {
  # Defining destinations with a focus on global and regional targets for a "Fierro-to-Cloud" perspective
  local -A targets=(
    ["Google DNS"]="8.8.8.8"
    ["Cloudflare"]="1.1.1.1"
    ["AWS Mexico"]="ec2.mx-central-1.amazonaws.com"
    ["K'aatech Resource"]="nt.kaatech.mx"
  )

  log_event "INFO" "Starting Multi-Cloud Latency Audit..."

  for name in "${!targets[@]}"; do
    local host="${targets[$name]}"
    local latency=""

    # Ping attempt with a 2s timeout and 4 packets to get an average latency
    latency=$(ping -c 4 -i 0.2 -W 2 "${host}" 2> /dev/null | tail -1 | awk -F '/' '{print $5}' || true)

    if [[ -n "${latency}" ]]; then
      log_event "INFO" "Latency to ${name} (${host}): ${latency} ms"
    else
      # Silent/informative error handling for the placeholder targets, which may not respond to ICMP or may be blocked by firewalls
      log_event "WARN" "Target ${name} (${host}) unreachable or ICMP blocked."
    fi
  done
}
