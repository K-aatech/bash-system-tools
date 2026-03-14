#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: piler-hardening.sh
# DESCRIPTION: Post-installation Security Hardening for Mail Piler.
# STANDARDS: GBSG Compliant | K'aatech Baseline v1.2.1
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Environment & Globals ---
# x-release-please-start-version
SUITE_VERSION="0.1.0"
# x-release-please-end-version
readonly SUITE_VERSION

# --- Bootstrap ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly LIB_LOGGING="${SCRIPT_DIR}/../lib/logging.sh"
readonly LIB_UTILS="${SCRIPT_DIR}/../lib/sys-utils.sh"
readonly LIB_NET="${SCRIPT_DIR}/../lib/net-utils.sh"

# 1. Configure persistence (KISA Namespace)
readonly LOG_DIR="${SCRIPT_DIR}/../logs"
export LOG_FILE="${LOG_FILE:-${LOG_DIR}/piler-hardening.log}"
[[ ! -d "${LOG_DIR}" ]] && mkdir -p "${LOG_DIR}"

# 2. Secure library loading
for lib in "${LIB_LOGGING}" "${LIB_UTILS}" "${LIB_NET}"; do
  if [[ -f "$lib" ]]; then
    # shellcheck source=/dev/null
    source "$lib"
  else
    echo "ERROR: Missing library: $lib" >&2
    exit 1
  fi
done

# --- Logic ---

# @description Runs pre-flight checks to ensure the environment is ready for hardening.
# @no-params
# @return 0 on success, exit 1 on missing dependencies or privileges.
run_preflight_checks() {
  print_section "Pre-flight Security Audit"

  require_root_privileges
  fetch_host_metadata

  log_event "INFO" "Targeting: ${KISA_HOSTNAME} (${KISA_DISTRO})"

  # 1. Elastic binary validation (searching in sbin and bin)
  log_event "INFO" "Searching for piler binaries in system PATH..."
  verify_binary_existence "piler"

  # 2. Validation of the Systemd service (the real indicator of success)
  log_event "INFO" "Validating Mail Piler service stack..."
  verify_service_status "piler" "piler-smtp" "pilersearch"

  log_event "OK" "Mail Piler installation and service stack detected."

  # 3. Verify port activity (using net-utils API)
  log_event "INFO" "Verifying core service ports..."
  verify_port_activity 80 25 # HTTP (For challenge) and SMTP (Vital for receiving emails)

  # 4. Verify Nginx bin and service
  log_event "INFO" "Validating Nginx infrastructure..."
  verify_binary_existence "nginx"
  verify_service_status "nginx"
}

# @description Orchestrates network security, captures identity, and delegates TLS.
# @return 0 on success, 1 on TLS failure.
apply_network_security() {
  print_section "Edge Security & TLS"

  # If the variables already exist (e.g., export FQDN="..."), they are retained.
  local fqdn="${FQDN:-}"
  local admin_email="${ADMIN_EMAIL:-}"
  local env_path="${SCRIPT_DIR}/../.env"

  # 1. Identity Resolution (lib/sys-utils.sh)
  resolve_identity_value fqdn "PILER_FQDN" "Enter FQDN for Piler" "${env_path}" || exit 1
  resolve_identity_value admin_email "PILER_ADMIN_EMAIL" "Enter admin email" "${env_path}" || exit 1

  # 2. Defining routes (Application-specific)
  local ssl_snippet="/etc/nginx/snippets/piler-ssl.conf"
  local cert_manual="/etc/piler/ssl/piler.crt"
  local key_manual="/etc/piler/ssl/piler.key"
  local piler_vhost="/etc/nginx/sites-available/piler.conf"

  # 3. TLS Configuration (Certbot/Manual + Snippet Generation, delegated to net-utils.sh
  # The last 3 empty parameters activate the library's interactive menu (Certbot vs. Manual)
  if ! configure_tls_edge \
    "$fqdn" \
    "$admin_email" \
    "$ssl_snippet" \
    "$cert_manual" \
    "$key_manual" \
    "" "" ""; then

    log_event "CRIT" "TLS setup phase failed or requires manual intervention."
    log_event "INFO" "Hardening process suspended to maintain Nginx stability."
    exit 1
  fi

  # 4. Global Hardening (Ciphers, HSTS, etc. en /etc/nginx/conf.d/, defined in net-utils/sys-utils)
  apply_nginx_hardening

  # 5. Linking the Snippet to the Vhost (WITHOUT RELOAD)
  # This new function (link_ssl_snippet) only edits the .conf file.
  if ! link_ssl_snippet "$piler_vhost" "$ssl_snippet"; then
    log_event "CRIT" "Failed to link SSL snippet to Vhost."
    exit 1
  fi

  log_event "OK" "Network security stack prepared. Waiting for final verification."
}

# @description Validates the final state of the hardening process.
# @no-params
# @return 0 on success, exit 1 on config failure.
finalize_hardening() {
  print_section "Hardening Verification"

  if safe_service_config_apply "nginx" "nginx -t" "reload"; then
    log_event "OK" "Security Hardening Suite completed for ${KISA_HOSTNAME}."
  else
    log_event "CRIT" "Hardening process failed at the final verification stage."
    exit 1
  fi

  log_event "INFO" "Performing final security post-check..."

  if verify_port_activity 443; then
    log_event "OK" "Hardening successful: Port 443 is now active and secure."
  else
    log_event "CRIT" "Hardening verification failed: Port 443 is still unreachable."
    log_event "WARN" "Please check Nginx logs and firewall rules."
    exit 1
  fi
}

# --- Main ---

main() {
  print_section "K'aatech Security Hardening Suite v${SUITE_VERSION}"

  run_preflight_checks
  apply_network_security
  # We could add Fail2Ban here in the future
  finalize_hardening
}

main "$@"
