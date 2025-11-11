# Mock the request global - amount exceeds limit
global "request" {
    value = {
        path = "secret/data/production/payment-gateway"
        entity = {
            metadata = {
                transaction_limit = "10000"
            }
        }
        data = {
            max_amount = "15000"  # Exceeds limit
        }
    }
}

# Mock the decimal import
mock "decimal" {
    module {
        source = "mock-decimal.sentinel"
    }
}

test {
    rules = {
        main = false  # Should fail because amount exceeds limit
        is_payment_request = true
    }
}

