#!/bin/bash

# ========================
# Create Sentinel policies
# ========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${PROJECT_ROOT}/scripts/log.sh"

create_policy() {
    local policy_name=$1
    local policy_file=$2
    local role_name=$3

    info "Creating policy: ${CYAN}${policy_name}${NC} from file: ${CYAN}${policy_file}${NC}"

    if [ ! -f "${policy_file}" ]; then
        error "Policy file ${CYAN}${policy_file}${NC} not found!"
        return 1
    fi

    if vault policy write "${policy_name}" "${policy_file}" 2>/dev/null; then
        info "Policy ${CYAN}${policy_name}${NC} created successfully from ${CYAN}${policy_file}${NC}"
        return 0
    else
        error "Failed to create policy ${CYAN}${policy_name}${NC}"
        return 1
    fi
}

info "Starting policy creation process..."

# 1. Junior Developer policy
create_policy "junior-dev" "./policy/junior-dev-policy.hcl" "Junior Developer"

# 2. Senior Developer policy
create_policy "senior-dev" "./policy/senior-dev-policy.hcl" "Senior Developer"

# 3. Security Admin policy
create_policy "security-admin" "./policy/security-admin-policy.hcl" "Security Admin"

info "Policy creation process completed!"