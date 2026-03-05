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
# Defensive initialization to avoid 'set -u' errors
fetch_network_metadata() {
  KISA_IFACE=""
  KISA_PRIMARY_IP="N/A"
  KISA_NETMASK="N/A"
  KISA_GW="N/A"

  # 1. Attempt to obtain an active interface via route (without DNS resolution)
  # We use timeout 2 to prevent the 'ip' command from hanging on zombie network stacks
  # shellcheck disable=SC2034
  KISA_IFACE=$(timeout 2 ip -4 route get 8.8.8.8 2> /dev/null | awk '/dev/ {print $5}' | head -n1 || echo "")

  # 2. Fallback: If there is no internet route, take the first physical interface with IP.
  if [[ -z "${KISA_IFACE}" ]]; then
    KISA_IFACE=$(ip -4 addr show up | awk '/state UP/ {print $2}' | tr -d ':' | grep -v 'lo' | head -n1 || echo "")
  fi

  if [[ -n "${KISA_IFACE}" ]]; then
    # shellcheck disable=SC2034
    KISA_PRIMARY_IP=$(ip -4 addr show "${KISA_IFACE}" | awk '/inet / {print $2}' | cut -d/ -f1 || echo "N/A")
    # shellcheck disable=SC2034
    KISA_NETMASK=$(ip -4 addr show "${KISA_IFACE}" | awk '/inet / {print $2}' | cut -d/ -f2 || echo "N/A")
    # shellcheck disable=SC2034
    KISA_GW=$(ip -4 route show default dev "${KISA_IFACE}" | awk '{print $3}' | head -n1 || echo "N/A")
  fi
}

fetch_dns_metadata() {
  # xargs removes extra spaces and line breaks, turning the list into a single line
  # shellcheck disable=SC2034
  KISA_DNS=$(grep '^nameserver' /etc/resolv.conf 2> /dev/null | awk '{print $2}' | xargs || echo "None")
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
  # We use a temporary variable to capture the output and avoid breaking the set -e pipe.
  local port_data
  port_data=$(ss -tunlpH 2> /dev/null) || true

  if [[ -n "${port_data}" ]]; then
    log_event "INFO" "Port Mapping (TCP/UDP LISTEN):"
    while read -r line; do
      # We clean spaces and format the output to be more readable, showing protocol, port, and service/process name.
      local fmt_line
      fmt_line=$(echo "${line}" | awk '{printf "  - %-5s %-10s %-20s", $1, $5, $7}')
      log_event "INFO" "${fmt_line}"
    done <<< "${port_data}"
  else
    log_event "OK" "No open listening ports detected or access denied."
  fi
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

# --- Block 4: Edge Security & TLS (Hardening) ---

check_port_availability() {
  local port="${1}"
  log_event "INFO" "Validating if port ${port} is open in local firewall..."

  # We use `ss` to see if something is already listening, or `nc` to test external connectivity if necessary.
  if ss -tuln | grep -q ":${port} "; then
    log_event "OK" "Port ${port} is active and listening."
    return 0
  else
    log_event "WARN" "Port ${port} is not listening. Ensure your Cloud/OS Firewall allows it."
    return 1
  fi
}

# Injects security headers and hardened SSL parameters
apply_nginx_hardening() {
  # 1. Security Guard: Is it Nginx and is it active?
  if ! command -v nginx > /dev/null 2>&1; then
    log_event "CRIT" "Nginx binary not found. Hardening aborted."
    return 1
  fi

  if ! systemctl is-active --quiet nginx; then
    log_event "WARN" "Nginx is installed but not running. Proceeding with config injection only."
  fi

  local policy_file="/etc/nginx/conf.d/kisa-hardening.conf"
  log_event "INFO" "Injecting KISA Security Policy into Nginx..."

  # 2. Policy generation (HSTS, TLS 1.2+, Ciphers)
  cat << EOF > "${policy_file}"
# KISA Security Baseline
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;

add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
EOF

  log_event "OK" "Security policy applied at ${policy_file}."
}

# Detects and configures SSL/TLS for Nginx in an agnostic way
configure_tls_edge() {
  local domain="${1}"
  local mode="${2:-manual}"     # manual | certbot
  local challenge="${3:-nginx}" # nginx | standalone | dns

  # 1. Use of check_dependencies (KISA Standard)
  local -a pkg_deps=()
  [[ "${mode}" == "certbot" ]] && pkg_deps+=("certbot" "python3-certbot-nginx")

  if [[ ${#pkg_deps[@]} -gt 0 ]]; then
    check_dependencies "${pkg_deps[@]}"
  fi

  # 2. TLS Orchestration
  case "${mode}" in
    "certbot")
      log_event "INFO" "Requesting Let's Encrypt cert via ${challenge} challenge..."

      local certbot_cmd="certbot --${challenge} -d ${domain} --non-interactive --agree-tos -m admin@${domain}"

      if eval "${certbot_cmd}"; then
        log_event "OK" "TLS certificate obtained successfully."
      else
        log_event "CRIT" "Certbot failed. Check DNS propagation or port 80/443."
        return 1
      fi
      ;;
    "manual")
      log_event "INFO" "Manual mode: Placeholder for custom .crt/.key logic."
      # Implementation of certificate path validation
      ;;
  esac
}
