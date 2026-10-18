public enum NotificationPlan {}

public extension NotificationPlan {
    static let reminderDays = 7
    static let recurringDays = 31
    static let reminderTitle = "今日の記録はまだです"
    static let reminderBody = "使ったお金か「支出なし」の印を入れておきましょう"

    static func notifications(
        today: LocalDate,
        reminderTime: ReminderTime?,
        recordedDates: Set<LocalDate>,
        recurrings: [Recurring],
        names: [EntryCategory.ID: String]
    ) -> [PlannedNotification] {
        let reminders = reminderTime.map { time in
            self.reminders(today: today, time: time, recorded: recordedDates)
        } ?? []

        let notices = recurrings.flatMap { recurring in
            self.notices(
                of: recurring,
                today: today,
                time: reminderTime ?? .morning,
                names: names
            )
        }

        return (reminders + notices).sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date < rhs.date
            }

            if lhs.time != rhs.time {
                return lhs.time < rhs.time
            }

            return lhs.key < rhs.key
        }
    }
}

private extension NotificationPlan {
    static func reminders(
        today: LocalDate,
        time: ReminderTime,
        recorded: Set<LocalDate>
    ) -> [PlannedNotification] {
        (0..<reminderDays)
            .map { today.adding(days: $0) }
            .filter { !recorded.contains($0) }
            .map { date in
                PlannedNotification(
                    key: "reminder",
                    date: date,
                    time: time,
                    title: reminderTitle,
                    body: reminderBody,
                    route: .entry(date)
                )
            }
    }

    static func notices(
        of recurring: Recurring,
        today: LocalDate,
        time: ReminderTime,
        names: [EntryCategory.ID: String]
    ) -> [PlannedNotification] {
        guard let daysBefore = recurring.remindDaysBefore else {
            return []
        }

        let memo = recurring.memo.flatMap { $0.isEmpty ? nil : $0 }
        let category = recurring.categoryId.flatMap { names[$0] }
        let name = memo ?? category ?? "固定費"
        let start = today.adding(days: daysBefore)
        let end = start.adding(days: recurringDays - 1)

        return recurring.dates(from: start, through: end).map { date in
            PlannedNotification(
                key: "recurring-\(recurring.id)",
                date: date.adding(days: -daysBefore),
                time: time,
                title: name,
                body: body(
                    amount: recurring.amount,
                    on: date,
                    daysBefore: daysBefore
                ),
                route: .recurring(recurring.id)
            )
        }
    }

    static func body(
        amount: Int,
        on date: LocalDate,
        daysBefore: Int
    ) -> String {
        let yen = "¥\(grouped(amount))"

        if daysBefore == 0 {
            return "今日は \(yen) の日です"
        }

        return "\(date.month)/\(date.day) に \(yen) です"
    }

    static func grouped(_ amount: Int) -> String {
        let digits = Array(String(abs(amount)))
        var text = ""

        for (index, digit) in digits.enumerated() {
            if index > 0, (digits.count - index) % 3 == 0 {
                text.append(",")
            }

            text.append(digit)
        }

        return amount < 0 ? "-\(text)" : text
    }
}
