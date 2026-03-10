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
export LOG_FILE="${LOG_FILE:-./logs/piler-hardening.log}"
[[ ! -d "$(dirname "$LOG_FILE")" ]] && mkdir -p "$(dirname "$LOG_FILE")"

# 2. Secure library loading
# shellcheck source=../lib/logging.sh
[[ -f "${LIB_LOGGING}" ]] && source "${LIB_LOGGING}"
# shellcheck source=../lib/sys-utils.sh
[[ -f "${LIB_UTILS}" ]] && source "${LIB_UTILS}"
# shellcheck source=../lib/net-utils.sh
[[ -f "${LIB_NET}" ]] && source "${LIB_NET}"

# --- Logic ---

# @description Runs pre-flight checks to ensure the environment is ready for hardening.
# @no-params
# @return 0 on success, exit 1 on missing dependencies or privileges.
run_preflight_checks() {
  print_section "Pre-flight Security Audit"

  require_root_privileges
  fetch_system_metadata

  log_event "INFO" "Targeting: ${KISA_HOSTNAME} (${KISA_DISTRO})"

  # 1. Elastic binary validation (searching in sbin and bin)
  log_event "INFO" "Searching for piler binaries in system PATH..."
  verify_binary_existence "piler"

  # 2. Validation of the Systemd service (the real indicator of success)
  log_event "INFO" "Validating Mail Piler service stack..."
  verify_service_status "piler.service" "piler-smtp.service" "pilersearch.service"

  log_event "OK" "Mail Piler installation and service stack detected."

  # 3. Verify port activity (using net-utils API)
  log_event "INFO" "Verifying core service ports..."
  verify_port_activity 80 443 25 # HTTP (For challenge), HTTPS (For service) and SMTP (Vital for receiving emails)
}

# @description Orchestrates network security and delegates TLS lifecycle to net-utils.
# @no-params
# @return 0 on success, 1 on TLS failure.
apply_network_security() {
  print_section "Edge Security & TLS"

  # 1. Nginx Configuration (Headers and Protocols, defined in net-utils/sys-utils)
  apply_nginx_hardening

  # 2. TLS/SSL Management (delegated to lib/net-utils.sh)
  if ! configure_tls_edge; then
    log_event "CRIT" "Network security phase failed during TLS configuration."
    return 1
  fi

  log_event "OK" "Network security and TLS stack configured successfully."
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
