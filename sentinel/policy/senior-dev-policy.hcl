# Senior devs can access all environments
path "secret/*" {
  capabilities = ["read", "list", "update"]
}

path "secret/production/*" {
  capabilities = ["read", "list"]
}