#!/usr/bin/env bash

# ========================
# Cleanup Sentinel Demo
# ========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${PROJECT_ROOT}/scripts/log.sh"

info "Starting Sentinel Demo cleanup..."

# =========================
# Delete Sentinel policies
# =========================
info "Deleting Sentinel policies..."

vault delete sys/policies/egp/production-hours
vault delete sys/policies/egp/gdpr-residency
vault delete sys/policies/rgp/policy-governance

info "Sentinel policies deleted!"

# =========================
# Delete users
# =========================
info "Deleting users..."

vault delete auth/userpass/users/alice
vault delete auth/userpass/users/bob
vault delete auth/userpass/users/charlie

info "Users deleted!"

# =========================
# Delete secrets
# =========================
info "Deleting secrets..."

vault kv delete secret/development/database
vault kv delete secret/staging/database
vault kv delete secret/production/database
vault kv delete secret/production/payment-gateway
vault kv delete secret/thai-customers/user-123

info "Secrets deleted!"

# =========================
# Delete identity entities
# =========================
info "Deleting identity entities..."

vault delete identity/entity/alice
vault delete identity/entity/bob
vault delete identity/entity/charlie

rm -rf "auth_accessor.txt"
rm -rf "alice_entity_id.txt"
rm -rf "bob_entity_id.txt"
rm -rf "charlie_entity_id.txt"

info "Identity entities deleted!"

# =========================
# Delete Vault policies
# =========================
info "Deleting Vault policies..."

vault delete sys/policies/acl/junior-dev
vault delete sys/policies/acl/senior-dev
vault delete sys/policies/acl/security-admin

info "Vault policies deleted!"

# =========================
info "Sentinel Demo cleanup completed!"