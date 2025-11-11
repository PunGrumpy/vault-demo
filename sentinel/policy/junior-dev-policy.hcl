# Junior dev can access dev/staging only
path "secret/data/development/*" {
  capabilities = ["read", "list"]
}

path "secret/data/staging/*" {
  capabilities = ["read", "list"]
}

# 🚨 Need Sentinel for production access
path "secret/data/production/*" {
  capabilities = ["read"]
}