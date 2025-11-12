global "request" {
    value = {
        path = "secret/data/thai-customers/user-123"
        connection = {
            remote_addr = "192.168.1.1"
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
        cidr_check = false
        main = false
    }
}

