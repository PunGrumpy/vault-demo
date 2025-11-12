#!/usr/bin/env bash

# ========================
# Setup Secret Recovery Demo
# ========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${PROJECT_ROOT}/scripts/log.sh"

info "Starting Secret Recovery Demo setup..."

# =========================
# Enable Secret Engine
# =========================
info "Enabling Secret Engine..."

vault secrets enable -path=secret-recovery kv-v1
vault secrets enable -path=pki pki
vault secrets enable -path=transform transform

# =========================
# Create Demo Secrets
# =========================
info "Creating Demo Secrets..."

vault kv put secret-recovery/development/database username="dev_user" password="dev_pass_123"
vault kv put secret-recovery/staging/database username="stg_user" password="stg_pass_456"
vault kv put secret-recovery/production/database username="prod_user" password="prod_pass_SUPER_SECRET"

vault secrets tune -max-lease-ttl=87600h pki
vault write -field=certificate pki/root/generate/internal \
    common_name="Vault Demo Root CA" \
    ttl=87600h > "${PROJECT_ROOT}/secret-recovery/ca_cert.pem"
vault write pki/config/urls \
    issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
    crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"

vault write transform/role/payments transformations=ccn-fpe
vault write transform/transformations/fpe/ccn-fpe \
  template=ccn \
  tweak_source=internal \
  allowed_roles=payments

info "Created Demo Secrets and PKI!"

# =========================
# Manual Snapshot
# =========================
info "Creating Manual Snapshot..."

vault operator raft snapshot save ./vault-snapshot-$(date +%Y%m%d%H%M%S).snap