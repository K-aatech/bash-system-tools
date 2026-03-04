#!/usr/bin/env bash
# ==============================================================================
# Script Name: install-piler.sh
# Description: K'aatech Security-First Deployment for Mail Piler.
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Environment & Globals (Governance) ---
# x-release-please-start-version
SUITE_VERSION="0.2.0"
# x-release-please-end-version
readonly SUITE_VERSION
# We use := to allow injection from CI/CD or Vault
: "${PILER_HOSTNAME:=""}"
: "${MYSQL_ROOT_PASS:=""}"
: "${MYSQL_PILER_PASS:=""}"

readonly PILER_USER="piler"
readonly PHP_V="8.3"

# --- Bootstrap ---
LIB_LOGGING="$(dirname "$0")/../lib/logging.sh"
LIB_UTILS="$(dirname "$0")/../lib/sys-utils.sh"
LIB_DEPLOY="$(dirname "$0")/../lib/deploy-utils.sh"

# shellcheck source=../lib/logging.sh
[[ -f "${LIB_LOGGING}" ]] && source "${LIB_LOGGING}"
# shellcheck source=../lib/sys-utils.sh
[[ -f "${LIB_UTILS}" ]] && source "${LIB_UTILS}"
# shellcheck source=../lib/deploy-utils.sh
[[ -f "${LIB_DEPLOY}" ]] && source "${LIB_DEPLOY}"

# --- Logic Layer ---

configure_deployment() {
  print_section "Configuration Discovery"

  # 1. Data discovery (KISA Namespace)
  fetch_host_metadata
  log_event "INFO" "Deploying on ${KISA_HOSTNAME} (${KISA_DISTRO})"

  # 2. Secure data entry
  request_input "PILER_HOSTNAME" "Enter Piler FQDN" 0
  request_input "MYSQL_ROOT_PASS" "Enter MariaDB Root Password" 1

  [[ -z "${MYSQL_PILER_PASS}" ]] && MYSQL_PILER_PASS=$(generate_secret 24)
}

initialize_infrastructure() {
  print_section "Infrastructure Setup"

  local -a deps=(wget openssl build-essential mariadb-server nginx "php${PHP_V}-fpm")
  check_dependencies "${deps[@]}"

  if ! id -u "${PILER_USER}" > /dev/null 2>&1; then
    useradd --system --no-create-home --shell /bin/false "${PILER_USER}"
    log_event "OK" "System user created."
  fi
}

# --- Main (Presentation Orchestrator) ---

main() {
  # PHASE 1: INITIALIZATION, GOVERNANCE & HOST CONTEXT
  print_section "PHASE 1: PRE-CHECKS, GOVERNANCE & HOST CONTEXT"
  ensure_root
  rotate_logs

  # UI Presentation
  log_event "INFO" "Starting K'aatech Deployment System v${SUITE_VERSION}"

  configure_deployment
  initialize_infrastructure

  print_section "Ready for Stage 3"
  log_event "OK" "Environment validated for ${KISA_HOSTNAME}. Secrets generated."
}

main "$@"
