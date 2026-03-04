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

# --- Data Persistence Layer ---

configure_database_schema() {
  print_section "Database Provisioning"

  local tmp_sql
  tmp_sql=$(mktemp /tmp/piler_schema.XXXXXX.sql)

  log_event "INFO" "Preparing SQL schema with secure credentials..."

  # We use the KISA_ namespace to identify the deployment source in the database.
  cat << EOF > "${tmp_sql}"
CREATE DATABASE IF NOT EXISTS piler CHARACTER SET 'utf8mb4';
CREATE USER IF NOT EXISTS 'piler'@'localhost' IDENTIFIED BY '${MYSQL_PILER_PASS}';
GRANT ALL PRIVILEGES ON piler.* TO 'piler'@'localhost';
SET PASSWORD FOR 'piler'@'localhost' = '${MYSQL_PILER_PASS}';
FLUSH PRIVILEGES;
EOF

  # Secure execution (avoids passwords in `ps aux`)
  # Assumes the user has root access to MariaDB via socket (default in Debian/Ubuntu)
  if mysql -u root < "${tmp_sql}"; then
    log_event "OK" "MariaDB: User '${PILER_USER}' and schema 'piler' provisioned."
  else
    log_event "CRIT" "MariaDB: Failed to provision database. Check credentials."
    rm -f "${tmp_sql}"
    exit 1
  fi
  rm -f "${tmp_sql}"
}

# --- Build & Compilation Layer ---

build_piler_source() {
  print_section "Source Compilation"

  local piler_tarball="https://github.com/jsuto/piler/archive/refs/heads/master.zip"

  cd "${WORKING_DIR}" || exit 1

  log_event "INFO" "Downloading latest source from GitHub..."
  wget -q "${piler_tarball}" -O piler-master.zip
  unzip -q piler-master.zip

  # We enter the extracted directory (the name is usually piler-master)
  cd piler-master || {
    log_event "CRIT" "Failed to enter build directory."
    exit 1
  }

  log_event "INFO" "Running autoconf and make (this may take a few minutes)..."

  # GBSG: We redirect the verbose output to a build log to avoid cluttering the dashboard
  local build_log="/var/log/piler_build.log"

  ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
    --with-database=mariadb --enable-tcpwrappers --enable-memcached \
    > "${build_log}" 2>&1

  log_event "INFO" "Compiling binaries..."
  make all >> "${build_log}" 2>&1

  log_event "INFO" "Installing to system paths..."
  make install >> "${build_log}" 2>&1

  log_event "OK" "Compilation finished. Details in ${build_log}"
}

# --- Main (Presentation Orchestrator) ---

main() {
  print_section "Mail Piler Deployment"
  log_event "INFO" "Starting K'aatech Deployment System v${SUITE_VERSION}"
  # PHASE 1: INITIALIZATION, GOVERNANCE & HOST CONTEXT
  print_section "PHASE 1: PRE-CHECKS, GOVERNANCE & HOST CONTEXT"
  ensure_root
  rotate_logs

  configure_deployment
  initialize_infrastructure

  configure_database_schema
  build_piler_source

  print_section "Build Stage Complete"
  log_event "OK" "Binaries installed and Database ready."
}

main "$@"
