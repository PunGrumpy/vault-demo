# Mock the request global - wrong IP address
global "request" {
    value = {
        path = "secret/data/thai-customers/user-123"  # Allowed path
        connection = {
            remote_addr = "192.168.1.1"  # Not allowed IP address
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
        main = false  # Should fail because IP is not in allowed CIDR
        check_cidr = false
        is_allowed_path = true
    }
}

