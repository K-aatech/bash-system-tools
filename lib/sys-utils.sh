# shellcheck shell=bash
# ==============================================================================
# LIBRARY: sys-utils.sh
# DESCRIPTION: Core system utilities for integrity, metadata, and user input.
# VERSION: 1.2.0
# STANDARDS: GBSG Compliant | K'aatech Baseline v1.1.0
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- ENVIRONMENT GUARD ---
if [[ -z "${BASH_VERSINFO:-}" || "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  printf "[CRIT] This library requires Bash >= 4.x\n" >&2
  exit 1
fi

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf "[CRIT] This file must be sourced, not executed.\n" >&2
  exit 1
fi

# Fallback logging to prevent execution failure if lib/logging.sh is absent
if ! command -v log_event > /dev/null 2>&1; then
  log_event() {
    local level="${1}"
    shift
    printf "[%s] %s\n" "${level}" "$*" >&2
  }
fi

# --- CONSTANTS ---

# @description Recommended permissions matrix for a secure baseline. (Security by Design)
# Format: "path:expected_mode"
readonly KISA_PATH_POLICY=(
  "/etc/passwd:644"
  "/etc/shadow:600"
  "/etc/group:644"
  "/etc/gshadow:600"
  "/etc/sudoers:440"
  "/etc/ssh/sshd_config:600"
)

# --- INTERNAL HELPERS ---

# @description Detects the system package manager.
# @return stdout String representing the package manager (apt-get, dnf, pacman, apk, unknown).
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

# --- PUBLIC API: SYSTEM INTEGRITY ---

# @description Ensures the script is running with root privileges.
# @exit 1 If the user is not root.
require_root_privileges() {
  if [[ "${EUID}" -ne 0 ]]; then
    log_event "CRIT" "This operation requires root privileges. Aborting."
    exit 1
  fi
}

# @description Verifies if specific binaries exist in the system PATH.
# @param $@ List of binary names to verify.
# @exit 1 If any binary is missing.
# Usage: check_binaries "nginx" "piler" "openssl"
verify_binary_existence() {
  local missing=()
  for bin in "$@"; do
    if ! command -v "$bin" > /dev/null 2>&1; then
      missing+=("$bin")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_event "CRIT" "Missing required binaries: ${missing[*]}"
    exit 1
  fi
}

# @description Checks the status of Systemd services.
# @param $@ List of service names (e.g.: check_services "nginx.service" "piler.service").
# @exit 1 If a service is not registered.
verify_service_status() {
  for svc in "$@"; do
    if ! systemctl list-unit-files | grep -q "$svc"; then
      log_event "CRIT" "Service not registered: $svc"
      exit 1
    fi
    if ! systemctl is-active --quiet "$svc"; then
      log_event "WARN" "Service $svc is registered but NOT running."
    fi
  done
}

# @description Validates dependencies with interactive auto-install support.
# @param $@ List of binaries required.
# @exit 1 If installation fails or is aborted.
install_missing_dependencies() {
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

# --- PUBLIC API: SECURITY AUDIT ---

# @description Performs a full audit based on the KISA_PATH_POLICY.
# @return int Number of issues found.
# Perform a full audit based on the predefined policy
audit_baseline_permissions() {
  local entry path expected
  local -i total_issues=0

  log_event "INFO" "Starting baseline security permission audit..."

  for entry in "${KISA_PATH_POLICY[@]}"; do
    path="${entry%%:*}"
    expected="${entry#*:}"

    if [[ -e "${path}" ]]; then
      # We reused verification logic from the verify_path_owner_mode function to ensure consistency and avoid code duplication
      verify_path_owner_mode "${path}" "${expected}" || ((total_issues++))
    fi
  done

  return "${total_issues}"
}

# @description Checks if a file has the exact expected mode.
# @param $1 Path to file.
# @param $2 Expected octal mode (e.g., 600).
# @return 0 on match, 1 on mismatch.
verify_path_owner_mode() {
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

# @description Audits the health of Docker engine and containers.
# @return 0 always (informative only).
audit_container_health() {
  # 1. Silent binary verification
  if ! command -v docker > /dev/null 2>&1; then
    log_event "INFO" "Docker engine not detected on this host."
    return 0
  fi

  # 2. Active socket verification
  if ! timeout 3 docker info > /dev/null 2>&1; then
    log_event "WARN" "Docker is installed but the daemon is NOT responding (Timeout or socket error)."
    return 0
  fi

  log_event "INFO" "Auditing Docker container health..."

  local total_c running_c failing_c
  total_c=$(docker ps -a -q 2> /dev/null | wc -l | xargs)
  running_c=$(docker ps -q 2> /dev/null | wc -l | xargs)
  # We filter only those that are not 'running' or 'removing'
  failing_c=$(docker ps -a --filter "status=exited" --filter "status=dead" --filter "status=created" --format "{{.Names}} ({{.Status}})" 2> /dev/null || true)

  log_event "INFO" "  Containers: Total=${total_c} | Running=${running_c}"

  if [[ -n "${failing_c}" ]]; then
    log_event "WARN" "Non-running containers detected:"
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      log_event "WARN" "    -> ${line}"
    done <<< "${failing_c}"
  else
    log_event "OK" "All containers are in a healthy/expected state."
  fi
}

# --- PUBLIC API: UI & INTERACTION ---

# @description Prints a standardized visual section header.
# @param $1 The title of the section.
# --- Visual Formatting Tools ---
print_section() {
  local title="$1"
  # Colors: 1;34m (Bold Blue), 1;36m (Bold Cyan), 0m (Reset)
  printf "\n\e[1;34m%s\e[0m\n" "======================================================================"
  printf "\e[1;36m  🚀 %s\e[0m\n" "$title"
  printf "\e[1;34m%s\e[0m\n" "======================================================================"
}

# @description Captures user input with support for secret (hidden) mode.
# @param $1 Variable name to store the input.
# @param $2 Prompt text for the user.
# @param $3 Secret flag (1 for hidden input, 0 for plain text).
request_input() {
  local var_name="${1}"
  local prompt_text="${2}"
  local is_secret="${3:-0}"
  local input_val=""

  # We only ask if the variable is empty and there is a TTY
  if [[ -z "${!var_name:-}" && -t 0 ]]; then
    printf "❓ [PROMPT] %s: " "${prompt_text}"
    if [[ "${is_secret}" -eq 1 ]]; then
      read -r -s input_val
      echo # Required line break after read -s
    else
      read -r input_val
    fi
    # Dynamic assignment to the global variable
    eval "${var_name}=\"${input_val}\""
  fi
}

# --- PUBLIC API: DATA DISCOVERY ---

# @description Exports system metadata into global KISA_ variables.
# @stdout Variables KISA_HOSTNAME, KISA_UPTIME, KISA_KERNEL, KISA_DISTRO, KISA_ARCH.
# --- Data Retrieval Only (Reusable) ---
fetch_host_metadata() {
  # Define suite global variables for data export
  # shellcheck disable=SC2034
  KISA_HOSTNAME=$(hostname -s 2> /dev/null || hostname || echo "localhost")
  # shellcheck disable=SC2034
  KISA_UPTIME=$(uptime -p 2> /dev/null || echo "unknown")
  # shellcheck disable=SC2034
  KISA_KERNEL=$(uname -r 2> /dev/null || echo "unknown")
  # shellcheck disable=SC2034
  KISA_DISTRO=$(grep '^PRETTY_NAME=' /etc/os-release 2> /dev/null | cut -d= -f2 | tr -d '"' || echo "Linux Generic")
  # shellcheck disable=SC2034
  KISA_ARCH=$(uname -m 2> /dev/null || echo "unknown")
}
