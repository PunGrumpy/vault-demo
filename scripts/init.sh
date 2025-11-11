#!/usr/bin/env bash

set -euo pipefail

# Color definitions
if [[ -t 1 ]]; then
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[0;33m'
    readonly CYAN='\033[0;36m'
    readonly RED='\033[0;31m'
    readonly BLUE='\033[0;34m'
    readonly RESET='\033[0m'
else
    readonly GREEN='' YELLOW='' CYAN='' RED='' BLUE='' RESET=''
fi

# File paths
readonly SCRIPT_DIR=$(dirname "$0")
readonly PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
readonly ENV_FILE=".env"
readonly ENV_EXAMPLE_FILE=".env.example"
readonly ENV_FILE_PATH="$PROJECT_ROOT/${ENV_FILE}"
readonly ENV_EXAMPLE_PATH="$PROJECT_ROOT/${ENV_EXAMPLE_FILE}"

# Logging functions
log_info() {
    echo -e "${CYAN}$1${RESET}"
}

log_success() {
    echo -e "${GREEN}$1${RESET}"
}

log_warning() {
    echo -e "${YELLOW}$1${RESET}"
}

log_error() {
    echo -e "${RED}$1${RESET}" >&2
}


# Validation functions
check_env_example_exists() {
    if [[ ! -f "$ENV_EXAMPLE_PATH" ]]; then
        log_error "Error: ${ENV_EXAMPLE_FILE} file not found"
        log_info "Please create ${YELLOW}${ENV_EXAMPLE_FILE}${RESET} file first"
        exit 1
    fi
}

check_env_file_exists() {
    if [[ -f "$ENV_FILE_PATH" ]]; then
        log_warning "Warning: ${ENV_FILE} file already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted."
            exit 0
        fi
    fi
}

# Parse .env.example file
parse_env_example() {
    local -a keys=()
    local -A defaults=()
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)= ]]; then
            local var_name="${BASH_REMATCH[1]}"
            keys+=("$var_name")
            
            if [[ "$line" =~ =\"([^\"]*)\" ]] || [[ "$line" =~ =\'([^\']*)\' ]]; then
                defaults["$var_name"]="${BASH_REMATCH[1]}"
            else
                defaults["$var_name"]=""
            fi
        fi
    done < "$ENV_EXAMPLE_PATH"
    
    if [[ ${#keys[@]} -eq 0 ]]; then
        log_error "Error: No environment variables found in ${ENV_EXAMPLE_FILE}"
        exit 1
    fi
    
    # Return values via global variables (bash limitation)
    ENV_KEYS=("${keys[@]}")
    declare -gA ENV_DEFAULTS
    for key in "${keys[@]}"; do
        ENV_DEFAULTS["$key"]="${defaults[$key]}"
    done
}

# Display variables to be configured
show_variables() {
    log_info "Reading environment variables from ${ENV_EXAMPLE_FILE}..."
    echo
    
    log_success "The following environment variables need to be configured (from ${ENV_EXAMPLE_FILE}):"
    for key in "${ENV_KEYS[@]}"; do
        echo -e "  ${BLUE}•${RESET} ${YELLOW}${key}${RESET}"
    done
    echo
}

# Collect values from user
collect_values() {
    log_info "Please enter values for each variable:"
    echo
    
    declare -gA ENV_VALUES
    for key in "${ENV_KEYS[@]}"; do
        local default_val="${ENV_DEFAULTS[$key]}"
        
        if [[ -n "$default_val" ]]; then
            echo -ne "  ${BLUE}${key}${RESET} [${CYAN}${default_val}${RESET}]: "
            read -r input_value
            ENV_VALUES["$key"]="${input_value:-$default_val}"
        else
            echo -ne "  ${BLUE}${key}${RESET}: "
            read -r input_value
            ENV_VALUES["$key"]="$input_value"
        fi
    done
}

# Create .env file
create_env_file() {
    log_info "Creating ${ENV_FILE} file..."
    
    > "$ENV_FILE_PATH"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            echo "$line" >> "$ENV_FILE_PATH"
            continue
        fi
        
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)= ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local value="${ENV_VALUES[$var_name]}"
            echo "${var_name}=\"${value}\"" >> "$ENV_FILE_PATH"
        else
            echo "$line" >> "$ENV_FILE_PATH"
        fi
    done < "$ENV_EXAMPLE_PATH"
    
    echo
    log_success "✓ Created ${YELLOW}${ENV_FILE}${RESET} file"
    log_success "Done!"
}

# Main function
main() {
    check_env_example_exists
    check_env_file_exists
    
    parse_env_example
    show_variables
    collect_values
    
    create_env_file
}

main "$@"
