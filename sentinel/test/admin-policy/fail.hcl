global "request" {
    value = {
        path = "sys/policies/acl/security-admin"
    }
}

global "identity" {
    value = {
        entity = {
            name = "Alice Wong"
            metadata = {
                role = "Junior Developer"
            }
        }
    }
}

test {
    rules = {
        precond = true
        main = false
    }
}

