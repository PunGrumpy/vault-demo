# Mock the request global that Vault provides
global "request" {
    value = {
        path = "secret/data/production/database"
        entity = {
            metadata = {
                role = "junior-engineer"  # Not senior-engineer, should fail
            }
        }
    }
}

# Mock the time import
mock "time" {
    data = {
        now = {
            weekday = 1  # Monday (working day)
            hour = 5     # Within business hours
        }
    }
}

test {
    rules = {
        main = false  # Should fail because role is not senior-engineer
        is_business_hours = true
        is_senior = false
        is_production_path = true
        # Note: is_working_day may not be evaluated due to short-circuit
    }
}

