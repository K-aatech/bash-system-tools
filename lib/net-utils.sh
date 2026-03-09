# shellcheck shell=bash
# ==============================================================================
# LIBRARY: net-utils.sh
# DESCRIPTION: K'aatech Network Audit & Security Library (Fierro-to-Cloud).
# VERSION: 1.2.1
# STANDARDS: GBSG Compliant | K'aatech Baseline v1.2.1
# ==============================================================================

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

# Fallback logging
if ! command -v log_event > /dev/null 2>&1; then
  log_event() {
    local level="${1}"
    shift
    printf "[%s] %s\n" "${level}" "$*" >&2
  }
fi

# --- PUBLIC API: NETWORK DISCOVERY ---

# @description Collects local network interface and routing metadata.
# @stdout Exports KISA_IFACE, KISA_PRIMARY_IP, KISA_NETMASK, KISA_GW.
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

# @description Collects DNS nameservers from the local resolver.
# @stdout Exports KISA_DNS.
fetch_dns_metadata() {
  # xargs removes extra spaces and line breaks, turning the list into a single line
  # shellcheck disable=SC2034
  KISA_DNS=$(grep '^nameserver' /etc/resolv.conf 2> /dev/null | awk '{print $2}' | xargs || echo "None")
}

# --- PUBLIC API: VITALITY & PERFORMANCE ---

# @description Verifies outbound internet access via ICMP.
# @return 0 on success, 1 on failure.
verify_internet_connectivity() {
  log_event "INFO" "Checking internet connectivity (Target: 8.8.8.8)..."
  if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    log_event "OK" "Internet access verified."
    return 0
  else
    log_event "CRIT" "No internet access detected."
    return 1
  fi
}

# @description Audits multi-cloud provider latency for performance baseline.
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

# --- PUBLIC API: SOCKET & PORT AUDIT ---

# @description Lists active listening ports and associated processes.
audit_listening_sockets() {
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

# @description Checks if a specific port is active in the local socket stack.
# @param $1 Port number.
# @return 0 if listening, 1 otherwise.
verify_port_activity() {
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

# --- PUBLIC API: EDGE SECURITY & TLS ---

# @description Injects security headers and hardened SSL parameters into Nginx.
# @exit 1 If Nginx is not installed.
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

  # 2. Generate DHParams if they do not exist (Extra security against Logjam)
  local dh_file="/etc/nginx/dhparam.pem"
  if [[ ! -f "${dh_file}" ]]; then
    log_event "INFO" "Generating DHParams (2048 bits). This may take a minute..."
    openssl dhparam -out "${dh_file}" 2048 > /dev/null 2>&1
  fi

  # 3. Policy generation (HSTS, TLS 1.2+, Ciphers)
  local policy_file="/etc/nginx/conf.d/kisa-hardening.conf"
  log_event "INFO" "Injecting KISA Security Policy into Nginx..."

  cat << EOF > "${policy_file}"
# KISA Security Baseline - Hardened Nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_dhparam ${dh_file};

# Security Headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
EOF

  log_event "OK" "Security policy applied at ${policy_file}."
}

# @description Manages TLS certificate acquisition and configuration.
# @param $1 Domain name.
# @param $2 Admin email.
# @param $3 Mode (manual | certbot).
# @param $4 Challenge type (nginx | standalone | dns).
# @param $5 Use staging (true | false).
configure_tls_edge() {
  local domain="${1}"
  local email="${2}"
  local mode="${3:-manual}"       # manual | certbot
  local challenge="${4:-nginx}"   # nginx | standalone | dns
  local use_staging="${5:-false}" # Staging mode

  local staging_flag=""
  [[ "${use_staging}" == "true" ]] && staging_flag="--staging"

  # 1. Use of check_dependencies (KISA Standard)
  local -a pkg_deps=()
  [[ "${mode}" == "certbot" ]] && pkg_deps+=("certbot" "python3-certbot-nginx")

  if [[ ${#pkg_deps[@]} -gt 0 ]]; then
    check_dependencies "${pkg_deps[@]}"
  fi

  # 2. TLS Orchestration
  case "${mode}" in
    "certbot")
      log_event "INFO" "Requesting Let's Encrypt cert for ${domain}. (Staging: ${use_staging})..."

      # El comando ahora incluye staging y la autorenovación es automática con el plugin de certbot
      local certbot_cmd="certbot --${challenge} -d ${domain} --non-interactive --agree-tos -m ${email} ${staging_flag}"

      if eval "${certbot_cmd}"; then
        log_event "OK" "TLS certificate process successful."
        # Verificación de autorenovación (dry-run rápido)
        certbot renew --dry-run > /dev/null 2>&1 && log_event "OK" "Auto-renewal verified."
      else
        log_event "CRIT" "Certbot failed. Check your challenge settings, DNS or firewall (ports 80/443)."
        return 1
      fi
      ;;
    "manual")
      log_event "WARN" "MANUAL MODE: Administrator intervention required."
      log_event "INFO" "Remediation instructions:"
      log_event "INFO" " 1. Place your certificate in: /etc/piler/ssl/piler.crt"
      log_event "INFO" " 2. Enter your private key in: /etc/piler/ssl/piler.key"
      log_event "INFO" " 3. Update the Nginx Vhost to point to these routes."
      mkdir -p /etc/piler/ssl
      ;;
  esac
}
