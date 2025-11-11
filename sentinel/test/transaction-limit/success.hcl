# Mock the request global that Vault provides
global "request" {
    value = {
        path = "secret/data/production/payment-gateway"
        entity = {
            metadata = {
                transaction_limit = "10000"
            }
        }
        data = {
            max_amount = "5000"  # Within limit
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
        main = true
        is_payment_request = true
    }
}

