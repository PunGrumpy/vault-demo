# Junior dev can access dev/staging only
path "secret/development/*" {
  capabilities = ["read", "list"]
}

path "secret/staging/*" {
  capabilities = ["read", "list"]
}

# 🚨 Need Sentinel for production access
path "secret/production/*" {
  capabilities = ["read"]
}