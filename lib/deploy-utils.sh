# shellcheck shell=bash
# ==============================================================================
# LIBRARY: deploy-utils.sh
# DESCRIPTION: Advanced deployment utilities for service & web management.
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

# --- PUBLIC API: DISCOVERY ---

# @description Dynamically detects the installed PHP-FPM socket.
# @stdout The absolute path to the .sock file.
fetch_php_fpm_socket() {
  local version socket
  # Attempt to detect version from binary
  version=$(php -v 2> /dev/null | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1,2 || echo "")

  if [[ -n "${version}" ]]; then
    socket="/var/run/php/php${version}-fpm.sock"
    if [[ -S "${socket}" ]]; then
      echo "${socket}"
      return 0
    fi
  fi

  # Fallback: find any active fpm socket
  find /var/run/php/ -name "php*-fpm.sock" 2> /dev/null | head -n 1
}

# --- PUBLIC API: SERVICE MANAGEMENT ---

# @description Orchestrates systemd service actions with validation.
# @param $1 Action (start, stop, restart, reload, enable).
# @param $2 Service name.
# @return 0 on success, 1 on failure or if service is missing.
manage_service_unit() {
  local action="${1}"
  local service="${2}"

  if ! systemctl list-unit-files "${service}.service" > /dev/null 2>&1; then
    log_event "WARN" "Service ${service} not found. Skipping ${action}."
    return 0
  fi

  log_event "INFO" "Executing systemd ${action} on ${service}..."
  if systemctl "${action}" "${service}" > /dev/null 2>&1; then
    log_event "OK" "Service ${service}: ${action} successful."
    return 0
  else
    log_event "CRIT" "Failed to ${action} ${service}. Systemd status code: $?"
    return 1
  fi
}

# --- PUBLIC API: WEB DEPLOYMENT ---

# @description Deploys an Nginx VirtualHost with syntax validation and rollback.
# @param $1 Configuration name (e.g., piler).
# @param $2 Source file path.
# @return 0 on success, 1 on syntax error or missing source.
deploy_nginx_vhost() {
  local conf_name="${1}"
  local src_file="${2}"
  local available="/etc/nginx/sites-available/${conf_name}"
  local enabled="/etc/nginx/sites-enabled/${conf_name}"

  log_event "INFO" "Deploying Nginx VirtualHost: ${conf_name}"

  if [[ ! -f "${src_file}" ]]; then
    log_event "CRIT" "Source config missing: ${src_file}"
    return 1
  fi

  # Ensure persistence (Copy to available, link to enabled)
  cp "${src_file}" "${available}"
  ln -sf "${available}" "${enabled}"

  if nginx -t > /dev/null 2>&1; then
    manage_service_unit "reload" "nginx"
  else
    log_event "CRIT" "Nginx syntax error. Rolling back ${conf_name}."
    rm -f "${available}" "${enabled}"
    return 1
  fi
}

# --- PUBLIC API: SECURITY AND SECRETS ---

# @description Generates a cryptographically secure random string.
# @param $1 Length (default 32).
# @stdout The generated secret string.
generate_secure_secret() {
  local len="${1:-32}"
  # Use openssl for entropy, tr to ensure shell/env compatibility
  openssl rand -base64 "${len}" 2> /dev/null | tr -d '/+=' | cut -c1-"${len}"
}
