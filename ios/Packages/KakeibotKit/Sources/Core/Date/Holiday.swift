public enum Holiday {}

public extension Holiday {
    static let supportedYears = 2022...2099

    static func contains(_ date: LocalDate) -> Bool {
        guard supportedYears.contains(date.year) else {
            return false
        }

        return isNamed(date) || isSubstitute(date) || isBetweenHolidays(date)
    }
}

private extension Holiday {
    static func isNamed(_ date: LocalDate) -> Bool {
        let day = date.day

        switch date.month {
        case 1: return day == 1 || isMonday(date, week: 2)
        case 2: return day == 11 || day == 23
        case 3: return day == springEquinox(in: date.year)
        case 4: return day == 29
        case 5: return (3...5).contains(day)
        case 7: return isMonday(date, week: 3)
        case 8: return day == 11
        case 9: return isMonday(date, week: 3) || day == autumnEquinox(in: date.year)
        case 10: return isMonday(date, week: 2)
        case 11: return day == 3 || day == 23
        default: return false
        }
    }

    static func isSubstitute(_ date: LocalDate) -> Bool {
        guard date.weekday != .sunday, !isNamed(date) else {
            return false
        }

        var previous = date.adding(days: -1)

        while isNamed(previous) {
            if previous.weekday == .sunday {
                return true
            }

            previous = previous.adding(days: -1)
        }

        return false
    }

    static func isBetweenHolidays(_ date: LocalDate) -> Bool {
        isNamed(date.adding(days: -1)) && isNamed(date.adding(days: 1))
    }

    static func isMonday(
        _ date: LocalDate,
        week: Int
    ) -> Bool {
        date.weekday == .monday && (date.day - 1) / 7 == week - 1
    }

    static func springEquinox(in year: Int) -> Int {
        equinox(base: 20.8431, year: year)
    }

    static func autumnEquinox(in year: Int) -> Int {
        equinox(base: 23.2488, year: year)
    }

    static func equinox(
        base: Double,
        year: Int
    ) -> Int {
        let years = year - 1980
        let day = base + 0.242194 * Double(years)
        return Int(day.rounded(.down)) - years / 4
    }
}
