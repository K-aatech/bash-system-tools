# shellcheck shell=bash
# ==============================================================================
# Script Name: sys-utils.sh
# This file is intended to be sourced, not executed directly.
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

# --- Visual Formatting Tools ---
print_section() {
  local title="$1"
  # Colors: 1;34m (Bold Blue), 1;36m (Bold Cyan), 0m (Reset)
  printf "\n\e[1;34m%s\e[0m\n" "======================================================================"
  printf "\e[1;36m  🚀 %s\e[0m\n" "$title"
  printf "\e[1;34m%s\e[0m\n" "======================================================================"
}

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

# Validate root privileges (Security by Design)
ensure_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    log_event "CRIT" "This operation requires root privileges. Aborting."
    exit 1
  fi
}

# Requests user input securely (without echo in terminal)
# Arguments: variable_name, prompt_text, is_secret (1|0)
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

# --- Virtualization & Containers ---
audit_container_status() {
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
