public enum Holiday {
    public static let supportedYears = 2022...2099

    public static func name(of date: LocalDate) -> String? {
        guard supportedYears.contains(date.year) else {
            return nil
        }

        if let name = namedHoliday(on: date) {
            return name
        }

        if isSubstitute(date) {
            return "振替休日"
        }

        return isBetweenHolidays(date) ? "国民の休日" : nil
    }

    public static func contains(_ date: LocalDate) -> Bool {
        name(of: date) != nil
    }

    public static func isDayOff(_ date: LocalDate) -> Bool {
        let isWeekend = date.weekday == .saturday || date.weekday == .sunday

        let isYearEnd = (date.month, date.day) == (12, 31)
            || (date.month == 1 && date.day <= 3)

        return isWeekend || isYearEnd || contains(date)
    }
}

private extension Holiday {
    static func namedHoliday(on date: LocalDate) -> String? {
        switch (date.month, date.day) {
        case (1, 1): "元日"
        case (1, _) where isMonday(date, week: 2): "成人の日"
        case (2, 11): "建国記念の日"
        case (2, 23): "天皇誕生日"
        case (3, springEquinox(in: date.year)): "春分の日"
        case (4, 29): "昭和の日"
        case (5, 3): "憲法記念日"
        case (5, 4): "みどりの日"
        case (5, 5): "こどもの日"
        case (7, _) where isMonday(date, week: 3): "海の日"
        case (8, 11): "山の日"
        case (9, _) where isMonday(date, week: 3): "敬老の日"
        case (9, autumnEquinox(in: date.year)): "秋分の日"
        case (10, _) where isMonday(date, week: 2): "スポーツの日"
        case (11, 3): "文化の日"
        case (11, 23): "勤労感謝の日"
        default: nil
        }
    }

    static func isNamed(_ date: LocalDate) -> Bool {
        namedHoliday(on: date) != nil
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
