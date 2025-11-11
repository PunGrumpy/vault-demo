#!/bin/bash

# ========================
# Create users with different roles and identity entities
# ========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${PROJECT_ROOT}/scripts/log.sh"

# Color definitions
CYAN='\033[0;36m'
NC='\033[0m'

create_user() {
    local username=$1
    local password=$2
    local policy=$3
    local role_name=$4

    info "Creating user: ${CYAN}${username}${NC} with role: ${CYAN}${role_name}${NC}"

    if vault write auth/userpass/users/"${username}" \
        password="${password}" \
        token_policies="${policy}" 2>/dev/null; then
        info "User ${CYAN}${username}${NC} created successfully with policy ${CYAN}${policy}${NC}"
        return 0
    else
        error "Failed to create user ${CYAN}${username}${NC}"
        return 1
    fi
}

create_identity() {
    local username=$1
    local policy=$2
    shift 2

    info "Creating identity entity: ${CYAN}${username}${NC}"
    
    local entity_id=$(vault write -field=id identity/entity \
        name="${username}" \
        policies="${policy}" \
        "$@" 2>/dev/null)
    
    if [ -n "$entity_id" ]; then
        local accessor=$(vault auth list -format=json | jq -r '.["userpass/"].accessor' 2>/dev/null)
        vault write identity/entity-alias \
            name="${username}" \
            canonical_id="${entity_id}" \
            mount_accessor="${accessor}" >/dev/null 2>&1
        info "Identity entity ${CYAN}${username}${NC} created"
        return 0
    else
        error "Failed to create identity entity ${CYAN}${username}${NC}"
        return 1
    fi
}

info "Starting user creation process..."

# 1. Junior Developer
create_user "alice" "alice123" "junior-dev" "Junior Developer"
create_identity "alice" "junior-dev" \
    metadata=role=junior-engineer \
    metadata=department=engineering \
    metadata=clearance_level=1

# 2. Senior Developer
create_user "bob" "bob123" "senior-dev" "Senior Developer"
create_identity "bob" "senior-dev" \
    metadata=role=senior-engineer \
    metadata=department=engineering \
    metadata=clearance_level=3 \
    metadata=transaction_limit=10000

# 3. Security Admin
create_user "charlie" "charlie123" "security-admin" "Security Admin"

info "User creation process completed!"