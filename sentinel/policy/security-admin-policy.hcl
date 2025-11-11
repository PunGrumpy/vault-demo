# Security admins have full access
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/policies/sentinel/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}