# shellcheck shell=bash
# ==============================================================================
# Script Name: deploy-utils.sh
# Description: Advanced deployment utilities for service & web management.
# Namespace:   KISA.lib.deploy
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# Dynamically detects the installed PHP-FPM socket (Data Retrieval)
get_php_fpm_socket() {
  local version socket
  # We prioritize technical precision over hardcoding, allowing for dynamic adaptation to the installed PHP version.
  version=$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1,2 2> /dev/null || echo "8.3")
  socket="/var/run/php/php${version}-fpm.sock"
  if [[ -S "${socket}" ]]; then
    echo "${socket}"
  else
    # Fallback: search for any active php-fpm socket if the detected one does not exist
    find /var/run/php/ -name "php*-fpm.sock" | head -n 1
  fi
}

# Abstraction of service management (Logic Separation)
manage_service() {
  local action="${1}"
  local service="${2}"

  if ! systemctl list-unit-files "${service}.service" > /dev/null 2>&1; then
    log_event "WARN" "Service ${service} not found. Skipping ${action}."
    return 0
  fi

  log_event "INFO" "Executing systemd ${action} on ${service}..."
  if systemctl "${action}" "${service}" > /dev/null 2>&1; then
    log_event "OK" "Service ${service}: ${action} successful."
  else
    log_event "CRIT" "Failed to ${action} ${service}. Systemd status code: $?"
    return 1
  fi
}

# Configuration of Nginx with previous validation (Security by Design)
setup_nginx_vhost() {
  local conf_name="${1}"
  local src_file="${2}"
  local available="/etc/nginx/sites-available/${conf_name}"
  local enabled="/etc/nginx/sites-enabled/${conf_name}"

  log_event "INFO" "Deploying Nginx VirtualHost: ${conf_name}"

  [[ ! -f "${src_file}" ]] && {
    log_event "CRIT" "Source config missing: ${src_file}"
    return 1
  }

  # Ensure persistence (Copy to available, link to enabled)
  cp "${src_file}" "${available}"
  ln -sf "${available}" "${enabled}"

  if nginx -t > /dev/null 2>&1; then
    manage_service "reload" "nginx"
  else
    log_event "CRIT" "Nginx syntax error. Rolling back ${conf_name}."
    rm -f "${available}" "${enabled}"
    return 1
  fi
}

# Generator of cryptographically secure secrets
generate_secret() {
  local len="${1:-32}"
  # `tr` removes conflicting characters for shell/PHP variables
  openssl rand -base64 "${len}" | tr -d '/+=' | cut -c1-"${len}"
}
