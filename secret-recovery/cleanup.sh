#!/usr/bin/env bash

# ========================
# Cleanup Secret Recovery Demo
# ========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${PROJECT_ROOT}/scripts/log.sh"

info "Starting Secret Recovery Demo cleanup..."

# =========================
# Delete Demo Secrets
# =========================
info "Deleting Demo Secrets..."

vault kv delete secret-recovery/development/database
vault kv delete secret-recovery/staging/database
vault kv delete secret-recovery/production/database

vault kv delete pki/root/generate/internal
vault kv delete pki/config/urls
rm -rf ca_cert.pem

vault kv delete transform/role/payments
vault kv delete transform/transformations/fpe/ccn-fpe

info "Demo Secrets and PKI deleted!"