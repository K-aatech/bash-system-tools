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

# --- Block 1: Local Context (El Fierro) ---

get_network_context() {
  local primary_ip gateway netmask interface
  log_event "INFO" "Collecting local network context..."

  # Identify the main output interface and its associated IP, netmask, and gateway
  interface=$(ip route get 8.8.8.8 2> /dev/null | awk '/dev/ {print $5}' | head -n1)

  if [[ -z "${interface}" ]]; then
    log_event "WARN" "No primary network interface detected."
    return 1
  fi

  primary_ip=$(ip -4 addr show "${interface}" | awk '/inet / {print $2}' | cut -d/ -f1)
  netmask=$(ip -4 addr show "${interface}" | awk '/inet / {print $2}' | cut -d/ -f2)
  gateway=$(ip route show default dev "${interface}" | awk '{print $3}' | head -n1)
  # If the previous command fails, fallback to the first default found.
  [[ -z "${gateway}" ]] && gateway=$(ip route | awk '/default/ {print $3}' | head -n1)

  log_event "INFO" "Local Context: [IP: ${primary_ip}] [Mask: /${netmask}] [GW: ${gateway}] [IF: ${interface}]"
}

get_dns_resolvers() {
  local nameservers
  log_event "INFO" "Auditing DNS Resolvers..."

  # Extract nameservers ignoring comments and empty lines
  nameservers=$(grep '^nameserver' /etc/resolv.conf | awk '{print $2}' | xargs)

  if [[ -n "${nameservers}" ]]; then
    log_event "INFO" "Configured DNS: ${nameservers}"
  else
    log_event "WARN" "No DNS nameservers found in /etc/resolv.conf"
  fi
}

# --- Block 2: Vitality and Ports (Services) ---

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

get_listening_ports() {
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

# --- Block 3: Latency and Resolution (Metrics) ---

check_multi_cloud_latency() {
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
    local latency

    # Ping attempt with a 2s timeout and 3 packets to get an average latency
    latency=$(ping -c 3 -i 0.2 -W 2 "${host}" 2> /dev/null | tail -1 | awk -F '/' '{print $5}')

    if [[ -n "${latency}" ]]; then
      log_event "INFO" "Latency to ${name} (${host}): ${latency} ms"
    else
      # Silent/informative error handling for the placeholder targets, which may not respond to ICMP or may be blocked by firewalls
      log_event "WARN" "Target ${name} (${host}) unreachable or ICMP blocked."
    fi
  done
}
