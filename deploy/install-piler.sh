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
: "${PILER_USER:="piler"}"

readonly PHP_V="8.3"
readonly WORKING_DIR="/tmp/piler_build"

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
  request_input "PILER_USER" "Enter system/db username (default: piler)" 0
  # Request the time zone for web visualization (Auto detect as default. e.g. America/Mexico_City)
  local current_tz
  current_tz=$(timedatectl show --property=Timezone --value 2> /dev/null || echo "UTC")
  request_input "DISPLAY_TZ" "Enter Display Timezone (default: ${current_tz})" 0
  : "${DISPLAY_TZ:="${current_tz}"}"

  # 3. Intelligent application password management
  if [[ -z "${MYSQL_PILER_PASS}" ]]; then
    # If it wasn't injected, we ask if you want to define it or generate it.
    printf "❓ [PROMPT] Enter password for '%s' (leave empty to auto-generate): " "${PILER_USER}"
    read -r -s user_db_pass
    echo
    if [[ -z "${user_db_pass}" ]]; then
      MYSQL_PILER_PASS=$(generate_secret 24)
      log_event "OK" "Auto-generated secure password for ${PILER_USER}: ${MYSQL_PILER_PASS}"
    else
      MYSQL_PILER_PASS="${user_db_pass}"
    fi
  fi
}

initialize_infrastructure() {
  print_section "Infrastructure Setup"

  mkdir -p "${WORKING_DIR}"

  # Manticore Official Repository Registration
  if ! command -v manticore > /dev/null 2>&1; then
    log_event "INFO" "Adding Manticore Search official repository..."
    wget -q https://repo.manticoresearch.com/manticore-repo.noarch.deb -O "${WORKING_DIR}/manticore-repo.deb"
    dpkg -i "${WORKING_DIR}/manticore-repo.deb" > /dev/null 2>&1
    apt-get update > /dev/null 2>&1
  fi

  # Proactive check for disk space before compilation (Prevention)
  local free_space
  free_space=$(df -m /var | awk 'NR==2 {print $4}')
  if [[ "${free_space}" -lt 1024 ]]; then
    log_event "WARN" "Low disk space on /var (${free_space}MB). Compilation might fail."
  fi

  # COMPLETE DEPENDENCY ARRAY (Based on the original + PHP 8.3)
  local -a deps=(
    # Compilation and System Tools
    build-essential wget unzip pkg-config ca-certificates cron rsyslog sysstat
    # Development Libraries (Crucial for ./configure)
    libmariadb-dev libssl-dev libtre-dev libzip-dev libcurl4-openssl-dev libwrap0-dev
    # Servers and Engines
    mariadb-server mariadb-client nginx manticore manticore-extra
    # Complete PHP 8.3 Stack
    "php${PHP_V}-fpm" "php${PHP_V}-mysql" "php${PHP_V}-cli" "php${PHP_V}-cgi"
    "php${PHP_V}-zip" "php${PHP_V}-ldap" "php${PHP_V}-gd" "php${PHP_V}-curl" "php${PHP_V}-xml"
    # Document Processing Tools (Piler needs this to index attachments)
    catdoc unrtf poppler-utils tnef
    # Python Utilities
    python3 python3-mysqldb
  )

  check_dependencies "${deps[@]}"

  if ! id -u "${PILER_USER}" > /dev/null 2>&1; then
    useradd --system --no-create-home --shell /bin/false "${PILER_USER}"
    log_event "OK" "System user created."
  fi
  chown -R "${PILER_USER}:${PILER_USER}" "${WORKING_DIR}"
}

# --- Data Persistence Layer ---

configure_database_schema() {
  print_section "Database Provisioning"

  local tmp_sql
  tmp_sql=$(mktemp /tmp/piler_schema.XXXXXX.sql)

  log_event "INFO" "Provisioning MariaDB for user: ${PILER_USER}"

  # We use the KISA_ namespace to identify the deployment source in the database.
  cat << EOF > "${tmp_sql}"
CREATE DATABASE IF NOT EXISTS piler CHARACTER SET 'utf8mb4';
CREATE USER IF NOT EXISTS '${PILER_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PILER_PASS}';
ALTER USER '${PILER_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PILER_PASS}';
GRANT ALL PRIVILEGES ON piler.* TO '${PILER_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

  # Secure execution (avoids passwords in `ps aux`)
  # Assumes the user has root access to MariaDB via socket (default in Debian/Ubuntu)
  if MYSQL_PWD="${MYSQL_ROOT_PASS}" mysql -u root < "${tmp_sql}"; then
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

# --- Service Configuration Layer ---

finalize_configuration() {
  print_section "System Integration"

  # 1. Secure directories and file permissions (Security by Design)
  local src_path="${WORKING_DIR}/piler-master"
  mkdir -p /etc/piler /var/piler/www /var/run/piler
  chown "${PILER_USER}:${PILER_USER}" /var/run/piler

  log_event "INFO" "Extracting configuration templates from source..."

  # 2. Recovering files from the official repository paths
  cp "${src_path}/contrib/webserver/piler-nginx.conf" /etc/piler/piler-nginx.conf.dist
  cp "${src_path}/etc/sphinx.conf.dist" /etc/piler/sphinx.conf
  cp "${src_path}/util/db-mysql.sql" /etc/piler/db-mysql.sql
  cp "${src_path}/etc/manticore.conf.dist" /etc/piler/manticore.conf.dist
  cp "${src_path}/etc/config-site.dist.php" /etc/piler/config-site.dist.php

  # 3. Importing the Database Schema (Data Persistence)
  log_event "INFO" "Importing SQL schema into MariaDB..."
  if MYSQL_PWD="${MYSQL_ROOT_PASS}" mysql -u root piler < /etc/piler/db-mysql.sql; then
    log_event "OK" "Database schema imported successfully."
  else
    log_event "WARN" "SQL import failed. Database might be incomplete."
  fi

  # 4. Web UI Configuration Files
  log_event "INFO" "Finalizing PHP web configuration..."
  local php_conf="/etc/piler/config-site.php"
  cp /etc/piler/config-site.dist.php "${php_conf}"

  sed -i -e "s%HOSTNAME%${PILER_HOSTNAME}%g" \
    -e "s%MYSQL_PASSWORD%${MYSQL_PILER_PASS}%g" "${php_conf}"

  # Inject extra variables like the monolith does
  {
    echo "\$config['SERVER_ID'] = 0;"
    echo "\$config['SPHINX_VERSION'] = 331;"
    echo "\$config['ARCHIVE_HOST'] = '${PILER_HOSTNAME}';"
  } >> "${php_conf}"

  # 5. Nginx Configuration with dynamic PHP-FPM socket detection (Integration with deploy-utils)
  local php_socket
  php_socket=$(get_php_fpm_socket)
  local nginx_tmp="/tmp/piler-nginx.conf"

  if [[ -f /etc/piler/piler-nginx.conf.dist ]]; then
    sed -e "s%PILER_HOST%${PILER_HOSTNAME}%g" \
      -e "s%PHP_FPM_SOCKET%${php_socket}%g" \
      /etc/piler/piler-nginx.conf.dist > "${nginx_tmp}"
    setup_nginx_vhost "piler.conf" "${nginx_tmp}"
    rm -f "${nginx_tmp}"
  else
    log_event "CRIT" "Nginx template missing from source."
  fi

  log_event "INFO" "Configuring Mail Piler environment..."

  # 6. Encryption & Permissions (Security by Design)
  if [[ ! -f /etc/piler/piler.key ]]; then
    dd if=/dev/urandom bs=56 count=1 of=/etc/piler/piler.key 2> /dev/null
    chown "${PILER_USER}:${PILER_USER}" /etc/piler/piler.key
    chmod 600 /etc/piler/piler.key
    log_event "OK" "Unique encryption key generated."
  fi

  # 7. Configuration of Manticore/Sphinx (Search Engine)
  log_event "INFO" "Configuring Manticore Search index..."
  cp /etc/piler/manticore.conf.dist /etc/piler/manticore.conf
  # ADJUSTMENT: Ensure the service can read your config file and that it has the correct permissions. This is crucial for security and functionality.
  chown "${PILER_USER}:${PILER_USER}" /etc/piler/manticore.conf
  chmod 644 /etc/piler/manticore.conf

  sed -i -e "s/MYSQL_HOSTNAME/localhost/g" \
    -e "s/MYSQL_DATABASE/piler/g" \
    -e "s/MYSQL_USERNAME/${PILER_USER}/g" \
    -e "s/MYSQL_PASSWORD/${MYSQL_PILER_PASS}/g" \
    /etc/piler/manticore.conf
}

activate_services() {
  print_section "Service Activation"
  log_event "INFO" "Linking systemd units..."
  # Create necessary symbolic links for systemd to recognize the services installed by 'make install'
  ln -sf /usr/libexec/piler/pilersearch.service /etc/systemd/system/
  ln -sf /usr/libexec/piler/piler.service /etc/systemd/system/
  ln -sf /usr/libexec/piler/piler-smtp.service /etc/systemd/system/

  # Reload systemd to detect new unit files from 'make install'
  systemctl daemon-reload

  # Enable and start core services
  local -a services=("piler" "piler-smtp" "pilersearch")
  for svc in "${services[@]}"; do
    manage_service "enable" "${svc}"
    manage_service "start" "${svc}"
  done

  log_event "OK" "All Mail Piler services are active."
}

configure_app_timezone() {
  print_section "Application Localization"

  log_event "INFO" "Syncing Web UI timezone to ${DISPLAY_TZ}..."

  # 1. Configure PHP-FPM (so that PHP's date() functions respond to the local zone)
  local php_ini="/etc/php/${PHP_V}/fpm/php.ini"
  local escaped_tz
  escaped_tz=$(echo "${DISPLAY_TZ}" | sed 's/\//\\\//g')

  if [[ -f "${php_ini}" ]]; then
    # We remove the semicolon (comment) and add the zone
    sed -i "s/^;date.timezone =.*/date.timezone = ${escaped_tz}/" "${php_ini}"
    sed -i "s/^date.timezone =.*/date.timezone = ${escaped_tz}/" "${php_ini}"
    manage_service "restart" "php${PHP_V}-fpm"
  fi

  # 2. Configure Piler (inject into config-site.php if necessary)
  # Some Piler modules can read this variable directly
  echo "\$config['TIMEZONE'] = '${DISPLAY_TZ}';" >> /etc/piler/config-site.php

  log_event "OK" "Web UI aligned to ${DISPLAY_TZ} while System remains UTC."
}

# --- Main (Presentation Orchestrator) ---

main() {
  trap 'rm -f /tmp/piler_schema.*.sql' EXIT
  print_section "Mail Piler Deployment"
  log_event "INFO" "Starting K'aatech Deployment System v${SUITE_VERSION}"
  log_event "INFO" "Deployment Target: ${PILER_HOSTNAME}"
  # PHASE 1: INITIALIZATION, GOVERNANCE & HOST CONTEXT
  print_section "PHASE 1: PRE-CHECKS, GOVERNANCE & HOST CONTEXT"
  ensure_root
  rotate_logs

  configure_deployment
  initialize_infrastructure

  configure_database_schema
  build_piler_source

  finalize_configuration

  configure_app_timezone

  activate_services

  print_section "Deployment Successful"
  log_event "OK" "Installation completed for ${KISA_HOSTNAME}."
  log_event "INFO" "Access your portal at: http://${PILER_HOSTNAME}"
}

main "$@"
