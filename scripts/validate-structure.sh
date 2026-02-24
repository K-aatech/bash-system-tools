#!/usr/bin/env bash

# Purpose: Validates the structural integrity of the repository against the Governance Baseline.
# Inputs: None.
# Outputs: Log messages to stdout/stderr.
# Dependencies: find
# Exit codes:
#  0 - Success
#  1 - Structural or Permission violation
# Documentation: docs/governance-baseline.md

set -euo pipefail
IFS=$'\n\t'

# --- Configuration (Constants) ---
readonly REQUIRED_DIRS=(
  ".github"
  "audit"
  "hardening"
  "maintenance"
  "scripts"
  "test/lib"
  "test/unit"
  "lib"
  "docs"
)
readonly REQUIRED_FILES=(
  ".pre-commit-config.yaml"
  "commitlint.config.cjs"
  "release-please-config.json"
  ".release-please-manifest.json"
  ".markdownlintignore"
  ".gitignore"
  ".env.example"
  ".editorconfig"
  "docs/governance-baseline.md"
  "docs/versioning.md"
  "docs/setup-checklist.md"
)

# --- Functions ---

# Description: Validates that a required command-line binary exists.
# Arguments: $1 - Command name
# Returns: 1 if not found, exits script.
require_command() {
  local cmd="$1"
  command -v "$cmd" > /dev/null 2>&1 || {
    echo -e "[\033[0;31mERROR\033[0m] Missing required command: $cmd" >&2
    exit 1
  }
}

# --- UI / UX Colors (ANSI 256-bit) ---
log_info() { echo -e "[\033[38;5;31mINFO\033[0m] $*"; }        # #1585B5 (K'aatech Accessible Blue)
log_warn() { echo -e "[\033[38;5;214mWARN\033[0m] $*"; }       # #FBCA04 (Amber)
log_error() { echo -e "[\033[38;5;124mERROR\033[0m] $*" >&2; } # #991B1B (Red)
log_success() { echo -e "[\033[38;5;71mSUCCESS\033[0m] $*"; }  # #4CAF50 (Green)

# Description: Checks for the existence of mandatory directories and files.
# Returns: 0 if all exist, 1 otherwise.
validate_existence() {
  local exit_code=0
  log_info "Verifying mandatory directories and normative files..."

  for dir in "${REQUIRED_DIRS[@]}"; do
    [[ -d "$dir" ]] || {
      log_error "Mandatory directory missing: $dir"
      exit_code=1
    }
  done

  for file in "${REQUIRED_FILES[@]}"; do
    [[ -f "$file" ]] || {
      log_error "Normative file missing: $file"
      exit_code=1
    }
  done
  return "$exit_code"
}

# Description: Audits files for correct execution bits (+x or -x).
# Returns: 0 if compliant, 1 if violations are found.
validate_executability() {
  local exit_code=0
  log_info "Auditing execution bits across protected zones..."

  # 1. Zone: Required Scripts (+x)
  # We look for files that are NOT executable, ignoring .gitkeep
  local non_execs

  if [[ -n "$(find scripts/ test/unit/ audit/ hardening/ maintenance/ -name ".gitkeep" -print -quit)" ]]; then
    log_warn "Found .gitkeep files in script zones. These are ignored for execution bit audit."
  fi

  non_execs=$(find scripts/ test/unit/ audit/ hardening/ maintenance/ -type f ! -name ".gitkeep" ! -executable)
  if [[ -n "$non_execs" ]]; then
    log_error "The following files MUST be executable (+x):\n$non_execs"
    log_info "Remediation: Run 'chmod +x <file_path>' to fix."
    exit_code=1
  fi

  # 2. Zone: Libraries and Docs (-x) - Executable bit prohibited
  # We look for files that ARE executable, ignoring .gitkeep
  local illegal_execs
  illegal_execs=$(find lib/ test/lib/ docs/ -type f ! -name ".gitkeep" -executable)
  if [[ -n "$illegal_execs" ]]; then
    log_error "Security violation. The following files MUST NOT be executable:\n$illegal_execs"
    log_info "Remediation: Run 'chmod -x <file_path>' to fix."
    exit_code=1
  fi

  return "$exit_code"
}

# Description: Checks for the presence of local .env files to prevent accidental leaks.
validate_environment_safety() {
  if [[ -f ".env" ]]; then
    log_warn "Local '.env' file detected. Ensure it is ignored by Git to avoid secret leaks."
    log_info "Check your .gitignore and run 'git rm --cached .env' if it was accidentally tracked."
  fi
}

# --- Signal Handling ---
# Description: Cleanup routine for signals and script termination.
# shellcheck disable=SC2329 # Explicitly disabled: invoked indirectly by 'trap'
cleanup() {
  local exit_code=$?
  if [[ "$exit_code" -ne 0 ]]; then
    log_error "Script interrupted or failed unexpectedly."
  fi
  exit "$exit_code"
}

# Trap signals: SIGINT (Ctrl+C), SIGTERM (Kill), ERR (Unexpected error)
trap cleanup SIGINT SIGTERM ERR

# Description: Main entry point for the validation logic.
main() {
  log_info "Initiating a structural governance and permissions audit..."

  # Ensure dependencies are met
  require_command "find"

  local final_status=0

  validate_existence || final_status=1
  validate_executability || final_status=1
  validate_environment_safety

  if [[ "$final_status" -eq 0 ]]; then
    log_success "✅ Validation successful: The repository complies with the governance contract."
  else
    log_error "❌ Validation failed: Structural or security inconsistencies were found."
    log_error "Please review the errors listed above and correct any missing permissions or files."
  fi

  exit "$final_status"
}

main "$@"
