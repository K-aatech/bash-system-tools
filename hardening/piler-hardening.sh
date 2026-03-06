#!/usr/bin/env bash
# ==============================================================================
# Script Name: piler-hardening.sh
# Description: Post-installation Security Hardening for Mail Piler.
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Bootstrap ---
LIB_LOGGING="$(dirname "$0")/../lib/logging.sh"
LIB_UTILS="$(dirname "$0")/../lib/sys-utils.sh"
LIB_NET="$(dirname "$0")/../lib/net-utils.sh"

# shellcheck source=../lib/logging.sh
[[ -f "${LIB_LOGGING}" ]] && source "${LIB_LOGGING}"
# shellcheck source=../lib/sys-utils.sh
[[ -f "${LIB_UTILS}" ]] && source "${LIB_UTILS}"
# shellcheck source=../lib/net-utils.sh
[[ -f "${LIB_NET}" ]] && source "${LIB_NET}"

# --- Logic ---

run_preflight_checks() {
  print_section "Pre-flight Security Audit"

  ensure_root
  fetch_host_metadata

  log_event "INFO" "Targeting: ${KISA_HOSTNAME}"

  # Verify that Piler is installed (find the main binary)
  if [[ ! -f "/usr/bin/piler" ]]; then
    log_event "CRIT" "Mail Piler binary not found. Please run install-piler.sh first."
    exit 1
  fi

  # Verify basic ports
  check_port_availability 80  # HTTP (For challenge)
  check_port_availability 443 # HTTPS (For service)
}

apply_network_security() {
  print_section "Edge Security & TLS"

  # 1. Nginx Configuration (Headers and Protocols)
  apply_nginx_hardening

  # 2. TLS/SSL Management
  printf "❓ [PROMPT] Use Certbot for Let's Encrypt? (y/n): "
  read -r use_certbot

  if [[ "${use_certbot,,}" != "y" ]]; then
    # Logic Manual explained to the user
    configure_tls_edge "N/A" "N/A" "manual"
    return 0
  fi

  # Capture of required data
  request_input "PILER_FQDN" "Enter FQDN (e.g. piler.domain.com)" 0
  request_input "ADMIN_EMAIL" "Enter your email address for important account notifications" 0

  # Challenge descriptors
  echo -e "\nSelect Challenge Type:"
  echo "1) nginx      - (Default) Best if Nginx is already running."
  echo "2) standalone - Use a temporary server (requires free port 80)."
  echo "3) dns        - Best for wildcards or restricted firewalls."

  printf "\nSelection [1-3]: "
  read -r ch_choice

  local sel_ch
  case $ch_choice in
    2) sel_ch="standalone" ;;
    3) sel_ch="dns" ;;
    *) sel_ch="nginx" ;;
  esac

  # Opción de Staging
  printf "❓ [PROMPT] Enable Staging mode (Dry-run)? (y/n): "
  read -r is_staging
  local staging_val="false"
  [[ "${is_staging,,}" == "y" ]] && staging_val="true"

  configure_tls_edge "${PILER_FQDN}" "${ADMIN_EMAIL}" "certbot" "${sel_ch}" "${staging_val}"
  #else
  #log_event "INFO" "Skipping automated TLS. Ensure manual certs are in /etc/piler/ssl/"
  #fi
}

finalize_hardening() {
  print_section "Hardening Verification"

  log_event "INFO" "Testing Nginx configuration syntax..."
  if nginx -t > /dev/null 2>&1; then
    log_event "OK" "Nginx configuration is valid. Reloading..."
    manage_service "reload" "nginx"
  else
    log_event "CRIT" "Nginx configuration test failed! Manual intervention required."
    exit 1
  fi

  log_event "OK" "Security Hardening Suite completed for ${KISA_HOSTNAME}."
}

# --- Main ---

main() {
  print_section "K'aatech Security Hardening Suite"

  run_preflight_checks
  apply_network_security
  # We could add Fail2Ban here in the future
  finalize_hardening
}

main "$@"
