#!/usr/bin/env bash

# ========================
# Setup Sentinel Demo
# ========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${PROJECT_ROOT}/scripts/log.sh"

info "Starting Sentinel Demo setup..."

# =========================
# Creating ACL policies
# =========================
info "Creating ACL policies..."

vault policy write junior-dev -<<EOF
path "secret/data/development/*" {
  capabilities = ["read", "list"]
}
path "secret/data/staging/*" {
  capabilities = ["read", "list"]
}
# Need Sentinel for production access
path "secret/data/production/*" {
  capabilities = ["read"]
}
EOF

vault policy write senior-dev -<<EOF
path "secret/data/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/*" {
  capabilities = ["list"]
}
EOF

vault policy write security-admin -<<EOF
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "sys/policies/egp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "sys/policies/rgp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

info "ACL policies created!"

# =========================
# Create users under auth/userpass
# =========================
info "Creating users under auth/userpass..."

vault auth enable userpass

vault write auth/userpass/users/alice \
  password="alice123" \
  policies="junior-dev"

vault write auth/userpass/users/bob \
  password="bob123" \
  policies="senior-dev"

vault write auth/userpass/users/charlie \
  password="charlie123" \
  policies="security-admin"

vault auth list -format=json | jq -r '.["userpass/"].accessor' > auth_accessor.txt

info "Creating identity entities..."

vault write identity/entity name="Alice Wong" policies="junior-dev" \
  metadata=role="Junior Developer" \
  | jq -r '.data.id' > alice_entity_id.txt
vault write identity/entity-alias name="alice" \
  canonical_id=$(cat alice_entity_id.txt) \
  mount_accessor=$(cat auth_accessor.txt)

vault write identity/entity name="Bob Smith" policies="senior-dev" \
  metadata=role="Senior Developer" \
  | jq -r '.data.id' > bob_entity_id.txt
vault write identity/entity-alias name="bob" \
  canonical_id=$(cat bob_entity_id.txt) \
  mount_accessor=$(cat auth_accessor.txt)

vault write identity/entity name="Charlie Chan" policies="security-admin" \
  metadata=role="Security Admin" \
  | jq -r '.data.id' > charlie_entity_id.txt
vault write identity/entity-alias name="charlie" \
  canonical_id=$(cat charlie_entity_id.txt) \
  mount_accessor=$(cat auth_accessor.txt)

info "Identity entities created!"

# =========================
# Create demo secrets
# =========================
info "Creating demo secrets..."

vault kv put secret/development/database username="dev_user" password="dev_pass_123"
vault kv put secret/staging/database username="stg_user" password="stg_pass_456"
vault kv put secret/production/database username="prod_user" password="prod_pass_SUPER_SECRET"
vault kv put secret/production/payment-gateway api_key="pk_live_XXXXXXXXXX" merchant_id="merchant_prod_001"
vault kv put secret/thai-customers/user-123 email="customer@thai.com" pii="sensitive_data"

info "Demo secrets created!"

# =========================
# Apply Sentinel policies
# =========================
info "Applying Sentinel policies..."

vault write sys/policies/egp/production-hours policy=@production-hours.sentinel \
  enforcement_level="hard-mandatory" \
  paths="secret/data/production/*"

vault write sys/policies/egp/gdpr-residency policy=@gdpr-residency.sentinel \
  enforcement_level="hard-mandatory" \
  paths="secret/data/thai-customers/*"

vault write sys/policies/rgp/policy-governance policy=@admin-policy.sentinel \
  enforcement_level="soft-mandatory"

info "Sentinel policies applied!"