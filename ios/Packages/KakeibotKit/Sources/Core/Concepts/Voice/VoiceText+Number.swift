import Foundation

extension VoiceText {
    static func number(from token: String) -> Int? {
        if let plain = Int(token) {
            return plain
        }

        var total = 0
        var section = 0
        var current: Int?

        for character in token {
            if let unit = smallUnits[character] {
                section += (current ?? 1) * unit
                current = nil
            } else if let digit = digit(of: character) {
                current = (current ?? 0) * 10 + digit
            } else if character == "万" {
                total += (section + (current ?? 0)) * 10000
                section = 0
                current = nil
            } else {
                return nil
            }
        }

        let value = total + section + (current ?? 0)
        return value > 0 ? value : nil
    }

    func amount(skipping skipped: Range<String.Index>?) -> Found<Int>? {
        let withYen = text.matches(of: Self.yenPattern)
            .filter { !Self.overlaps($0.range, skipped) }
            .compactMap { match in
                Self.number(from: String(match.output.1))
                    .map { Found(value: $0, range: match.range) }
            }
            .last { (1...Self.maxAmount).contains($0.value) }

        if let withYen {
            return withYen
        }

        let withSign = text.matches(of: Self.signPattern)
            .filter { !Self.overlaps($0.range, skipped) }
            .compactMap { match in
                Int(match.output.1).map { Found(value: $0, range: match.range) }
            }
            .last { (1...Self.maxAmount).contains($0.value) }

        if let withSign {
            return withSign
        }

        return text.matches(of: Self.barePattern).lazy
            .filter { !Self.overlaps($0.range, skipped) }
            .compactMap { match in
                Int(match.output.1).map { Found(value: $0, range: match.range) }
            }
            .first { (1...Self.maxAmount).contains($0.value) }
    }

    func date(today: LocalDate) -> Found<LocalDate>? {
        for (word, days) in Self.relativeDays {
            if let range = text.range(of: word) {
                return Found(value: today.adding(days: days), range: range)
            }
        }

        if let match = text.firstMatch(of: Self.daysAgoPattern),
           let days = Self.number(from: String(match.output.1)),
           days <= Self.maxDaysAgo {
            return Found(value: today.adding(days: -days), range: match.range)
        }

        if let match = text.firstMatch(of: Self.weekdayPattern),
           let weekday = Self.weekdays[String(match.output.2)] {
            let isLastWeek = match.output.1 != nil
            return Found(
                value: Self.recent(weekday, lastWeek: isLastWeek, today: today),
                range: match.range
            )
        }

        if let match = text.firstMatch(of: Self.monthDayPattern),
           let month = Self.number(from: String(match.output.1)),
           let day = Self.number(from: String(match.output.2)),
           let date = Self.recent(month: month, day: day, today: today) {
            return Found(value: date, range: match.range)
        }

        if let match = text.firstMatch(of: Self.dayPattern),
           let day = Self.number(from: String(match.output.1)),
           let date = Self.recent(day: day, today: today) {
            return Found(value: date, range: match.range)
        }

        return nil
    }
}

private extension VoiceText {
    static let maxAmount = 999_999_999

    static let maxDaysAgo = 60

    static let relativeDays: [(String, Int)] = [
        ("一昨日", -2),
        ("おととい", -2),
        ("昨日", -1),
        ("きのう", -1),
        ("昨夜", -1),
        ("昨晩", -1),
        ("ゆうべ", -1),
        ("今日", 0),
        ("きょう", 0),
        ("今朝", 0),
        ("今夜", 0),
        ("今晩", 0)
    ]

    static let weekdays: [String: Weekday] = [
        "月": .monday, "火": .tuesday, "水": .wednesday, "木": .thursday,
        "金": .friday, "土": .saturday, "日": .sunday
    ]

    static let kanjiDigits: [Character: Int] = [
        "〇": 0, "零": 0, "一": 1, "二": 2, "三": 3, "四": 4,
        "五": 5, "六": 6, "七": 7, "八": 8, "九": 9
    ]

    static let smallUnits: [Character: Int] = ["十": 10, "百": 100, "千": 1000]

    static var yenPattern: Regex<(Substring, Substring)> {
        #/([0-9〇零一二三四五六七八九十百千万]+)\s*(?:円|えん)/#
    }

    static var signPattern: Regex<(Substring, Substring)> {
        #/¥\s*([0-9]+)/#
    }

    static var daysAgoPattern: Regex<(Substring, Substring)> {
        #/([0-9〇一二三四五六七八九十]{1,3})日前/#
    }

    static var weekdayPattern: Regex<(Substring, Substring?, Substring)> {
        #/(先週の?)?([月火水木金土日])曜日?/#
    }

    static var barePattern: Regex<(Substring, Substring)> {
        #/([0-9]+)(?![0-9])(?!\s*[日月年時分秒個つ人回件%％番])/#
    }

    static var monthDayPattern: Regex<(Substring, Substring, Substring)> {
        #/([0-9〇一二三四五六七八九十]{1,3})月([0-9〇一二三四五六七八九十]{1,3})日/#
    }

    static var dayPattern: Regex<(Substring, Substring)> {
        #/([0-9〇一二三四五六七八九十]{1,3})日(?![前間分])/#
    }

    static func digit(of character: Character) -> Int? {
        if character.isASCII {
            return character.wholeNumberValue
        }

        return kanjiDigits[character]
    }

    static func overlaps(
        _ range: Range<String.Index>,
        _ other: Range<String.Index>?
    ) -> Bool {
        other.map(range.overlaps) ?? false
    }

    static func recent(
        _ weekday: Weekday,
        lastWeek: Bool,
        today: LocalDate
    ) -> LocalDate {
        let todayIndex = today.weekday.daysSinceMonday
        let targetIndex = weekday.daysSinceMonday

        guard lastWeek else {
            return today.adding(days: -((todayIndex - targetIndex + 7) % 7))
        }

        return today.adding(days: targetIndex - todayIndex - 7)
    }

    static func recent(
        month: Int,
        day: Int,
        today: LocalDate
    ) -> LocalDate? {
        guard let date = LocalDate(year: today.year, month: month, day: day) else {
            return nil
        }

        return date > today ? LocalDate(year: today.year - 1, month: month, day: day) : date
    }

    static func recent(
        day: Int,
        today: LocalDate
    ) -> LocalDate? {
        if let date = LocalDate(yearMonth: today.yearMonth, day: day), date <= today {
            return date
        }

        return LocalDate(yearMonth: today.yearMonth.adding(months: -1), day: day)
    }
}
