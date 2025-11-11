#!/bin/bash

# ========================
# Create demo secrets using vault kv put
# ========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${PROJECT_ROOT}/scripts/log.sh"

create_secret() {
    local secret_path=$1
    shift

    info "Creating secret: ${CYAN}${secret_path}${NC}"

    if vault kv put "${secret_path}" "$@" 2>/dev/null; then
        info "Secret ${CYAN}${secret_path}${NC} created"
    else
        error "Failed to create secret ${CYAN}${secret_path}${NC}"
        return 1
    fi
}

info "Starting secrets creation..."

# Enable KV v2
if vault secrets enable -path=secret kv-v2 2>/dev/null; then
    info "KV v2 enabled at ${CYAN}secret${NC}"
elif vault secrets list -detailed | grep -q "secret/.*kv"; then
    warn "KV v2 already enabled at ${CYAN}secret${NC}"
else
    error "Failed to enable KV v2"
    exit 1
fi

# Create secrets
create_secret "secret/development/database" \
    username="dev_user" \
    password="dev_pass_123"

create_secret "secret/staging/database" \
    username="stg_user" \
    password="stg_pass_456"

create_secret "secret/production/database" \
    username="prod_user" \
    password="prod_pass_SUPER_SECRET"

create_secret "secret/production/payment-gateway" \
    api_key="pk_live_XXXXXXXXXX" \
    merchant_id="merchant_prod_001"

create_secret "secret/thai-customers/user-123" \
    email="customer@thai.com" \
    pii="sensitive_data"

# Verify
info "Verifying secrets..."
vault kv list secret/ 2>/dev/null && info "Secrets verified"

info "Secrets creation completed!"