global "request" {
    value = {
        path = "sys/policies/acl/security-admin"
    }
}

global "identity" {
    value = {
        entity = {
            name = "Charlie Chan"
            metadata = {
                role = "Security Admin"
            }
        }
    }
}

test {
    rules = {
        precond = true
        main = true
    }
}

