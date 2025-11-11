# Mock the request global that Vault provides
global "request" {
    value = {
        path = "secret/data/production/database"
        entity = {
            metadata = {
                role = "senior-engineer"
            }
        }
    }
}

# Mock the time import
mock "time" {
    data = {
        now = {
            weekday = 1  # Monday (1-5 are working days)
            hour = 5     # Within business hours (2-11)
        }
    }
}

test {
    rules = {
        main = true
        is_working_day = true
        is_business_hours = true
        is_senior = true
        is_production_path = true
    }
}