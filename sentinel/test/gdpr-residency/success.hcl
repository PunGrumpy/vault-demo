# Mock the request global that Vault provides
global "request" {
    value = {
        path = "secret/thai-customers/user-123"
        connection = {
            remote_addr = "129.41.56.7"  # Allowed IP address
        }
    }
}

# Mock the sockaddr import
mock "sockaddr" {
    module {
        source = "mock-sockaddr.sentinel"
    }
}

test {
    rules = {
        main = true
        check_cidr = true
        is_allowed_path = true
    }
}

