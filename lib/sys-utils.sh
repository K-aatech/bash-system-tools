#!/usr/bin/env bash
# ==============================================================================
# Script Name: sys-utils.sh
# Description: Multi-distro support for dependencies and security checks. (GBSG compliant).
# Standards: GBSG Compliant | K'aatech Baseline v1.1.0
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# Fallback logging to prevent execution failure if lib/logging.sh is absent
if ! command -v log_event > /dev/null 2>&1; then
  log_event() {
    local level="${1}"
    shift
    printf "[%s] %s\n" "${level}" "$*" >&2
  }
fi

# Recommended Permissions Matrix (Security by Design)
# Format: "path:expected_mode"
readonly SECURITY_PATH_POLICY=(
  "/etc/passwd:644"
  "/etc/shadow:600"
  "/etc/group:644"
  "/etc/gshadow:600"
  "/etc/sudoers:440"
  "/etc/ssh/sshd_config:600"
)

# Perform a full audit based on the predefined policy
audit_baseline_permissions() {
  local entry path expected
  local -i total_issues=0

  log_event "INFO" "Starting baseline security permission audit..."

  for entry in "${SECURITY_PATH_POLICY[@]}"; do
    path="${entry%%:*}"
    expected="${entry#*:}"

    if [[ -e "${path}" ]]; then
      # We reused verification logic from the check_path_mode function to ensure consistency and avoid code duplication
      check_path_mode "${path}" "${expected}" || ((total_issues++))
    fi
  done

  return "${total_issues}"
}

# Checks if a file has the exact or more restrictive mode
# Arguments: path, expected_mode (e.g., 600)
check_path_mode() {
  local path="${1}"
  local expected="${2}"
  local current

  # Validation of prior existence to avoid stat errors
  if [[ ! -e "${path}" ]]; then
    log_event "WARN" "Path not found: ${path}"
    return 1
  fi

  current=$(stat -c "%a" "${path}")

  if [[ "${current}" != "${expected}" ]]; then
    log_event "CRIT" "Permission mismatch on ${path}: expected ${expected}, found ${current}"
    return 1
  fi
  return 0
}

# Internal function to detect the package manager
_get_package_manager() {
  local os_id=""

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    # We use a subshell to avoid polluting the global namespace with os-release variables
    os_id=$(source /etc/os-release && echo "${ID:-} ${ID_LIKE:-}")

    case "${os_id}" in
      *ubuntu* | *debian* | *kali* | *raspbian*) echo "apt-get" ;;
      *fedora* | *centos* | *rhel* | *almalinux*) echo "dnf" ;;
      *arch* | *manjaro*) echo "pacman" ;;
      *alpine*) echo "apk" ;;
      *) echo "unknown" ;;
    esac
  else
    echo "unknown"
  fi
}

# Validate dependencies with interactive support and cron compatibility
check_dependencies() {
  local -a missing_deps=()
  local bin pkg_manager user_response
  local -i is_interactive=0

  [[ -t 0 ]] && is_interactive=1
  pkg_manager=$(_get_package_manager)

  for bin in "$@"; do
    command -v "${bin}" > /dev/null 2>&1 || missing_deps+=("${bin}")
  done

  [[ ${#missing_deps[@]} -eq 0 ]] && return 0

  log_event "WARN" "Missing dependencies: ${missing_deps[*]}"

  if [[ ${is_interactive} -eq 1 ]]; then
    if [[ "${pkg_manager}" == "unknown" ]]; then
      log_event "CRIT" "Unsupported distribution. Please install dependencies manually: ${missing_deps[*]}"
      exit 1
    fi

    # GBSG: Use printf for prompts and read to local variable
    printf "[PROMPT] Detected %s. Install missing? (y/N): " "${pkg_manager}"
    read -r -n 1 user_response
    printf "\n"

    if [[ "${user_response}" =~ ^[Yy]$ ]]; then
      # Security Fix: Removed 'sudo' as script must run as root
      case "${pkg_manager}" in
        "apt-get") apt-get update -qq && apt-get install -y "${missing_deps[@]}" ;;
        "dnf") dnf install -y "${missing_deps[@]}" ;;
        "pacman") pacman -Sy --noconfirm "${missing_deps[@]}" ;;
        "apk") apk add "${missing_deps[@]}" ;;
      esac
    else
      log_event "CRIT" "Aborted by user."
      exit 1
    fi
  else
    log_event "CRIT" "Non-interactive: Install ${missing_deps[*]} manually."
    exit 1
  fi
}
