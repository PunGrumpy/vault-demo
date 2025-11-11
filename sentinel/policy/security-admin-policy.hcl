# Security admins have full access
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/policies/egp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/policies/rgp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}