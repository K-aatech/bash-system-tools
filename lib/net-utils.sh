# shellcheck shell=bash
# ==============================================================================
# LIBRARY: net-utils.sh
# DESCRIPTION: K'aatech Network Audit & Security Library (Fierro-to-Cloud).
# VERSION: 1.2.1
# STANDARDS: GBSG Compliant | K'aatech Baseline v1.2.1
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# ======================================================================
# --- ENVIRONMENT GUARD ---
# ======================================================================

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

# ======================================================================
# --- PUBLIC API: NETWORK DISCOVERY ---
# ======================================================================

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

# ======================================================================
# --- PUBLIC API: VITALITY & PERFORMANCE ---
# ======================================================================

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

# ======================================================================
# --- PUBLIC API: SOCKET & PORT AUDIT ---
# ======================================================================

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

# @description Verifies if one or multiple ports are open and reachable.
# @param $@ List of port numbers to verify.
# @return 0 if all ports are active, 1 if at least one is unreachable.
verify_port_activity() {
  local -i exit_code=0
  local ports=("$@")

  if [[ ${#ports[@]} -eq 0 ]]; then
    log_event "WARN" "No ports provided to verify_port_activity."
    return 1
  fi

  for port in "${ports[@]}"; do
    if ss -tuln | grep -q ":${port} "; then
      log_event "OK" "Port ${port} is active and listening."
    else
      log_event "WARN" "Port ${port} is NOT reachable or service is down."
      exit_code=1
    fi
  done

  return "${exit_code}"
}

# ======================================================================
# --- PUBLIC API: EDGE SECURITY & TLS ---
# ======================================================================

# @description Injects security headers and hardened SSL parameters into Nginx.
# @exit 1 If Nginx is not installed.
# Injects security headers and hardened SSL parameters
apply_nginx_hardening() {
  # 1. Security Guard: Is it Nginx and is it active?
  verify_binary_existence "nginx"

  if ! systemctl is-active --quiet nginx; then
    log_event "WARN" "Nginx is installed but not running. Injected config will only take effect after a manual start/reload."
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

# @description Orchestrates TLS certificate acquisition and generates Nginx snippets.
# @param $1 domain        FQDN/Domain.
# @param $2 email         Admin Email.
# @param $3 snippet_file  Path to save the Nginx snippet.
# @param $4 target_cert   Manual path for instructions.
# @param $5 target_key    Manual path for instructions.
# @param $6 mode          (Optional) manual | certbot.
# @param $7 challenge     (Optional) nginx | standalone.
# @param $8 staging       (Optional) true | false.
# @return 0 on success, 1 on failure.
configure_tls_edge() {
  local domain="${1:-}"
  local email="${2:-}"
  local snippet_file="${3:-}"
  local target_cert="${4:-}"
  local target_key="${5:-}"
  local mode="${6:-}"
  local challenge="${7:-nginx}"
  local use_staging="${8:-false}"

  # 1. Mode Intelligence: If not defined, ask the user
  if [[ -z "${mode}" ]]; then
    if [[ -t 0 ]]; then
      printf "❓ [PROMPT] Use Certbot for Let's Encrypt? (y/n): "
      read -r resp
      [[ "${resp,,}" == "y" ]] && mode="certbot" || mode="manual"
    else
      mode="manual" # Fallback for non-interactive processes
    fi
  fi

  # 2. Manual Flow
  if [[ "${mode}" == "manual" ]]; then
    log_event "WARN" "MANUAL MODE: Administrator intervention required."
    log_event "INFO" "Remediation instructions:"
    log_event "INFO" " 1. Place your certificate in: ${target_cert}"
    log_event "INFO" " 2. Enter your private key in: ${target_key}"
    log_event "INFO" " 3. Update the Nginx Vhost to include: ${snippet_file}"
    mkdir -p "$(dirname "${target_cert}")"
    return 1
  fi

  # 3. Certbot (Autonomous) Workflow
  # Validate required binaries before proceeding
  verify_binary_existence "certbot"

  # Capture missing data if we are in terminal mode
  if [[ -t 0 ]]; then
    [[ -z "${domain}" ]] && request_input domain "Enter FQDN (e.g. piler.domain.com)" 0
    [[ -z "${email}" ]] && request_input email "Enter your email address for important account notifications" 0

    # Internal Challenge Menu
    if [[ -z "${7:-}" ]]; then # Only ask if no arguments were passed (assuming full interactive flow)
      echo -e "\nSelect Certbot Challenge:\n1) nginx (Default)\n2) standalone\n3) dns (not supported yet)"
      printf "Selection [1-3]: "
      read -r ch_choice
      case "${ch_choice}" in
        2) challenge="standalone" ;;
        #3) challenge="dns" ;;
        *) challenge="nginx" ;;
      esac

      printf "❓ [PROMPT] Enable Staging mode (Dry-run)? (y/n): "
      read -r is_stg
      [[ "${is_stg,,}" == "y" ]] && use_staging="true"
    fi
  fi

  # Final validation of critical data
  [[ -z "${domain}" || -z "${email}" ]] && {
    log_event "CRIT" "Missing FQDN or Email for TLS."
    return 1
  }

  # Certbot execution
  local staging_flag=""
  [[ "${use_staging}" == "true" ]] && staging_flag="--staging"

  log_event "INFO" "Requesting Let's Encrypt cert for ${domain} (${challenge})..."

  # Note: Using certonly to keep the Vhost clean and use the snippet instead
  if certbot certonly --"${challenge}" -d "${domain}" --non-interactive --agree-tos -m "${email}" ${staging_flag}; then
    local cert_src="/etc/letsencrypt/live/${domain}/fullchain.pem"
    local key_src="/etc/letsencrypt/live/${domain}/privkey.pem"

    # 4. Snippet Generation (Common path for success)
    log_event "INFO" "Generating Nginx SSL snippet at ${snippet_file}..."
    mkdir -p "$(dirname "${snippet_file}")"
    printf "ssl_certificate %s;\nssl_certificate_key %s;\n" "${cert_src}" "${key_src}" > "${snippet_file}"

    log_event "OK" "TLS certificate process successful."
    [[ "${use_staging}" == "false" ]] && certbot renew --dry-run > /dev/null 2>&1 && log_event "OK" "Auto-renewal verified."
    return 0
  else
    log_event "CRIT" "Certbot failed. Check DNS, firewall or challenge settings."
    return 1
  fi
}

# ======================================================================
# --- PUBLIC API: SERVICE EDGE ORCHESTRATION ---
# ======================================================================

# @description Safely validates and applies configuration changes to a service.
# @param $1 Service name (e.g., nginx, postfix).
# @param $2 Validation command (e.g., "nginx -t", "postfix check").
# @param $3 Action to perform if valid (reload | restart).
# @return 0 on success, 1 on validation or action failure.
safe_service_config_apply() {
  local service_name="${1}"
  local validation_cmd="${2}"
  local action="${3:-reload}"

  log_event "INFO" "Validating configuration for ${service_name} before ${action}..."

  # 1. Verificar si el binario del servicio existe
  if ! command -v "${service_name}" > /dev/null 2>&1; then
    log_event "CRIT" "Service binary '${service_name}' not found in PATH."
    return 1
  fi

  # 2. Ejecutar comando de validación de sintaxis
  if eval "${validation_cmd}" > /dev/null 2>&1; then
    log_event "OK" "${service_name} configuration syntax is valid."

    # 3. Aplicar cambio usando nuestra API de control de servicios
    if control_service_state "${action}" "${service_name}"; then
      log_event "OK" "Service ${service_name} ${action}ed successfully."
      return 0
    else
      log_event "CRIT" "Failed to ${action} ${service_name}."
      return 1
    fi
  else
    log_event "CRIT" "Syntax error detected in ${service_name} config. Aborting ${action}."
    return 1
  fi
}
