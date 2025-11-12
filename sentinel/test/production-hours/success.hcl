global "request" {
    value = {
        path = "secret/data/production/database"
        entity = {
            metadata = {
                role = "Senior Developer"
            }
        }
    }
}

mock "time" {
    data = {
        now = {
            weekday = 1
            hour = 5
        }
    }
}

test {
    rules = {
        precond = true
        workdays = true
        workhours = true
        senior = true
        main = true
    }
}
