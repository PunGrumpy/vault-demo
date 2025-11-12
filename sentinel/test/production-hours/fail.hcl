global "request" {
    value = {
        path = "secret/data/production/database"
        entity = {
            metadata = {
                role = "Junior Developer"
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
        senior = false
        main = false
    }
}

