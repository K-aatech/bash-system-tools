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
  local version
  # We prioritize technical precision over hardcoding, allowing for dynamic adaptation to the installed PHP version.
  version=$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1,2 2> /dev/null || echo "8.3")

  local socket="/var/run/php/php${version}-fpm.sock"
  echo "${socket}"
}

# Abstraction of service management (Logic Separation)
manage_service() {
  local action="${1}"
  local service="${2}"

  # We delegated the presentation to logging.sh
  log_event "INFO" "Executing systemd ${action} on ${service}..."

  if systemctl "${action}" "${service}" > /dev/null 2>&1; then
    log_event "OK" "Service ${service}: ${action} successful."
  else
    log_event "CRIT" "Failed to ${action} ${service}. Check logs."
    return 1
  fi
}

# Configuration of Nginx with previous validation (Security by Design)
setup_nginx_vhost() {
  local conf_name="${1}"
  local src_file="${2}"
  local target="/etc/nginx/sites-enabled/${conf_name}"

  log_event "INFO" "Deploying Nginx VirtualHost: ${conf_name}"

  [[ ! -f "${src_file}" ]] && {
    log_event "CRIT" "Missing config: ${src_file}"
    return 1
  }

  # Atomic link and test
  ln -sf "${src_file}" "${target}"

  if nginx -t > /dev/null 2>&1; then
    manage_service "reload" "nginx"
  else
    log_event "CRIT" "Nginx syntax error in ${conf_name}. Rolling back."
    rm -f "${target}"
    return 1
  fi
}

# Generator of cryptographically secure secrets
generate_secret() {
  local len="${1:-32}"
  # `tr` removes conflicting characters for shell/PHP variables
  openssl rand -base64 "${len}" | tr -d '/+=' | cut -c1-"${len}"
}
