#!/bin/bash

# ========================
# Apply Sentinel EGP and RGP policies to Vault
# ========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${PROJECT_ROOT}/scripts/log.sh"

# Color definitions
CYAN='\033[0;36m'
NC='\033[0m'

apply_egp_policy() {
    local policy_name=$1
    local policy_file=$2
    local enforcement_level=$3
    local paths=$4

    info "Applying EGP policy: ${CYAN}${policy_name}${NC} from file: ${CYAN}${policy_file}${NC}"

    if [ ! -f "${policy_file}" ]; then
        error "Policy file ${CYAN}${policy_file}${NC} not found!"
        return 1
    fi

    # Read the policy content
    local policy_content=$(cat "${policy_file}")

    # Apply the EGP policy
    if vault write "sys/policies/egp/${policy_name}" \
        policy="${policy_content}" \
        enforcement_level="${enforcement_level}" \
        paths="${paths}" 2>/dev/null; then
        info "EGP policy ${CYAN}${policy_name}${NC} applied successfully"
        return 0
    else
        error "Failed to apply EGP policy ${CYAN}${policy_name}${NC}"
        return 1
    fi
}

apply_rgp_policy() {
    local policy_name=$1
    local policy_file=$2
    local enforcement_level=$3

    info "Applying RGP policy: ${CYAN}${policy_name}${NC} from file: ${CYAN}${policy_file}${NC}"

    if [ ! -f "${policy_file}" ]; then
        error "Policy file ${CYAN}${policy_file}${NC} not found!"
        return 1
    fi

    # Read the policy content
    local policy_content=$(cat "${policy_file}")

    # Apply the RGP policy
    if vault write "sys/policies/rgp/${policy_name}" \
        policy="${policy_content}" \
        enforcement_level="${enforcement_level}" 2>/dev/null; then
        info "RGP policy ${CYAN}${policy_name}${NC} applied successfully"
        return 0
    else
        error "Failed to apply RGP policy ${CYAN}${policy_name}${NC}"
        return 1
    fi
}

info "Starting Sentinel policy application process..."

# Apply EGP policies
info "Applying EGP (Endpoint Governing Policies)..."

# 1. GDPR Residency Policy
apply_egp_policy "gdpr-residency" \
    "./gdpr-residency.sentinel" \
    "hard-mandatory" \
    "secret/data/thai-customers/*"

# 2. Production Hours Policy
apply_egp_policy "production-hours" \
    "./production-hours.sentinel" \
    "hard-mandatory" \
    "secret/data/production/*"

# 3. Transaction Limit Policy
apply_egp_policy "transaction-limit" \
    "./transaction-limit.sentinel" \
    "hard-mandatory" \
    "secret/data/production/payment/*"

# Apply RGP policies
info "Applying RGP (Role Governing Policies)..."

# 1. Policy Governance RGP
apply_rgp_policy "policy-governance" \
    "./policy-governance.sentinel" \
    "soft-mandatory"

info "Sentinel policy application process completed!"

