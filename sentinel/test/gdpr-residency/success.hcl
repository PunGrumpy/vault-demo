
global "request" {
    value = {
        path = "secret/data/thai-customers/user-123"
        connection = {
            remote_addr = "129.41.56.7"
        }
    }
}

mock "sockaddr" {
    module {
        source = "mock-sockaddr.sentinel"
    }
}

test {
    rules = {
        precond = true
        cidr_check = true
        main = true
    }
}

