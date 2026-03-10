#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: validate-structure.sh
# DESCRIPTION: Validates repository integrity against K'aatech Governance.
# STANDARDS: K'aatech Engineering v1.2.1 / Google Shell Style Guide
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Environment & Globals ---
# x-release-please-start-version
SUITE_VERSION="0.1.0"
# x-release-please-end-version
readonly SUITE_VERSION

# --- Bootstrap ---
# We securely determine the script directory and set up paths to libraries with fail-fast logic.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
LIB_LOGGING="${SCRIPT_DIR}/../lib/logging.sh"
readonly LIB_LOGGING
LIB_SYS_UTILS="${SCRIPT_DIR}/../lib/sys-utils.sh"
readonly LIB_SYS_UTILS

# 1. Load Core Logging
if [[ -f "$LIB_LOGGING" ]]; then
  # shellcheck source=../lib/logging.sh
  source "$LIB_LOGGING"
else
  printf "[ERROR] Logging library not found at %s\n" "$LIB_LOGGING" >&2
  exit 1
fi

# 2. Configure Persistence (Namespace KISA)
# It allows overwriting from the environment, e.g.: LOG_FILE=/var/log/custom ./script.sh
export LOG_FILE="${LOG_FILE:-./logs/structure-audit.log}"
export LOG_FILE
# Ensure the logs directory exists before starting
[[ ! -d "${LOG_FILE}" ]] && mkdir -p "${LOG_FILE}"

# 3. Load System Utilities
if [[ -f "$LIB_SYS_UTILS" ]]; then
  # shellcheck source=../lib/sys-utils.sh
  source "$LIB_SYS_UTILS"
else
  log_event "CRIT" "Utility library not found at $LIB_SYS_UTILS"
  exit 1
fi

# --- Configuration (Governance Baseline) ---
readonly REQUIRED_DIRS=(
  ".github" "audit" "deploy" "hardening" "maintenance"
  "scripts" "test/lib" "test/unit" "lib" "docs"
)

readonly REQUIRED_FILES=(
  ".pre-commit-config.yaml" "commitlint.config.cjs" "release-please-config.json"
  ".release-please-manifest.json" ".markdownlintignore" ".gitignore"
  ".env.example" ".editorconfig" "docs/governance-baseline.md"
  "docs/versioning.md" "docs/setup-checklist.md" "lib/logging.sh"
  "lib/sys-utils.sh" "lib/net-utils.sh"
)

# Execution bit enforcement zones
readonly EXEC_REQUIRED_ZONES=("scripts" "test/unit" "audit" "deploy" "hardening" "maintenance")
readonly EXEC_PROHIBITED_ZONES=("lib" "test/lib" "docs")

# --- Audit Functions ---

# @description Validates presence of mandatory structure.
verify_structure_existence() {
  local exit_code=0
  log_event "INFO" "Verifying mandatory directories and normative files..."

  for dir in "${REQUIRED_DIRS[@]}"; do
    [[ -d "$dir" ]] || {
      log_event "CRIT" "Mandatory directory missing: $dir"
      log_event "INFO" "Remediation: mkdir -p $dir && touch $dir/.gitkeep"
      exit_code=1
    }
  done

  for file in "${REQUIRED_FILES[@]}"; do
    [[ -f "$file" ]] || {
      log_event "CRIT" "Normative file missing: $file"
      log_event "INFO" "Remediation: Restore $file from the Baseline Template."
      exit_code=1
    }
  done
  return "$exit_code"
}

# @description Audits execution bits (POSIX and Windows-Git-Index).
# 1. Zone: Must be executable (+x)
# 2. Zone: Must NOT be executable (-x)
verify_execution_policy() {
  local exit_code=0
  local non_execs=""
  local illegal_execs=""
  local zone files

  log_event "INFO" "Auditing execution bits across protected zones..."

  # Environment Detection: Are we on a file system hostile to permissions (Windows)?
  local use_git_validation=0
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    log_event "WARN" "Windows environment detected. Using Git Index for permission audit."
    use_git_validation=1
  fi

  if [[ "$use_git_validation" -eq 1 ]]; then
    # Valitation via Git Index (755 mode for executables)
    for zone in "${EXEC_REQUIRED_ZONES[@]}"; do
      # Looking for files in the zone that do NOT have 755 mode in the index
      files=$(git ls-files --stage "$zone" | grep -v "100755" | grep -v ".gitkeep" | cut -f2 || true)
      if [[ -n "$files" ]]; then
        non_execs+="${files}"$'\n'
      fi
    done

    # Validating files in prohibited zones that have 755 mode in the index (Mode 644 expected)
    for zone in "${EXEC_PROHIBITED_ZONES[@]}"; do
      files=$(git ls-files --stage "$zone" | grep "100755" | cut -f2 || true)
      if [[ -n "$files" ]]; then
        illegal_execs+="${files}"$'\n'
      fi
    done
  else
    # Standard validation for Linux/POSIX/CI environments (Original with find)
    non_execs=$(find "${EXEC_REQUIRED_ZONES[@]}" -type f ! -name ".gitkeep" ! -executable 2> /dev/null || true)
    illegal_execs=$(find "${EXEC_PROHIBITED_ZONES[@]}" -type f ! -name ".gitkeep" -executable 2> /dev/null || true)
  fi

  # --- Report and Remediation ---
  # Results are trimmed to avoid false positives from whitespace-only outputs
  if [[ -n "${non_execs//[[:space:]]/}" ]]; then
    # Delete duplicates with sort -u for clean output
    local clean_non_execs
    clean_non_execs=$(echo -e "$non_execs" | sort -u)
    log_event "CRIT" "The following files MUST be executable (+x):$clean_non_execs"

    # Environment specific remediation instructions
    if [[ "$use_git_validation" -eq 1 ]]; then
      log_event "INFO" "Remediation (Windows): Run 'git update-index --chmod=+x <file>'"
    else
      log_event "INFO" "Remediation: Run 'chmod +x <file>'"
    fi
    exit_code=1
  fi

  if [[ -n "${illegal_execs//[[:space:]]/}" ]]; then
    local clean_illegal_execs
    clean_illegal_execs=$(echo -e "$illegal_execs" | sort -u)
    log_event "CRIT" "Security violation. The following files MUST NOT be executable:$clean_illegal_execs"

    # Environment specific remediation instructions
    if [[ "$use_git_validation" -eq 1 ]]; then
      log_event "INFO" "Remediation (Windows): Run 'git update-index --chmod=-x <file>'"
    else
      log_event "INFO" "Remediation: Run 'chmod -x <file>'"
    fi
    exit_code=1
  fi

  return "$exit_code"
}

# @description Ensures sensitive environment files are not leaked.
verify_leak_prevention() {
  if [[ -f ".env" ]]; then
    log_event "CRIT" "Local '.env' file detected. This is a risk in CI/CD pipelines."
    log_event "INFO" "Remediation: rm .env && git rm --cached .env (if tracked)"
    log_event "INFO" "Ensure it is in .gitignore | Use CI Secrets for environment variables."
    return 1
  fi
}

# --- Main ---
main() {
  log_event "START" "Initiating structural governance audit v${SUITE_VERSION}..."

  # Delegated dependency check to sys-utils.sh
  verify_binary_existence "find" "git" "sort"

  local final_status=0

  verify_structure_existence || final_status=1
  verify_execution_policy || final_status=1
  verify_leak_prevention || final_status=1

  if [[ "$final_status" -eq 0 ]]; then
    log_event "OK" "✅ Repository complies with the governance contract."
  else
    log_event "CRIT" "❌ Governance validation failed."
  fi

  exit "$final_status"
}

main "$@"
