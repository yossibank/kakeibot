public enum NotificationPlan {
    public struct Shortage: Hashable, Sendable {
        public let recurringId: Recurring.ID
        public let date: LocalDate
        public let walletName: String
        public let amount: Int

        public init(
            recurringId: Recurring.ID,
            date: LocalDate,
            walletName: String,
            amount: Int
        ) {
            self.recurringId = recurringId
            self.date = date
            self.walletName = walletName
            self.amount = amount
        }
    }

    public static let reminderDays = 30
    public static let recurringDays = 31
    public static let maxCount = 64

    public static func notifications(
        today: LocalDate,
        reminderTime: ReminderTime?,
        recordedDates: Set<LocalDate>,
        recurrings: [Recurring],
        names: [EntryCategory.ID: String],
        shortages: [Shortage] = []
    ) -> [PlannedNotification] {
        let reminders = reminderTime.map { time in
            self.reminders(today: today, time: time, recorded: recordedDates)
        } ?? []

        let notices = recurrings.flatMap { recurring in
            self.notices(
                of: recurring,
                today: today,
                time: reminderTime ?? .morning,
                names: names,
                shortages: shortages
            )
        }

        let sorted = (reminders + notices).sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date < rhs.date
            }

            if lhs.time != rhs.time {
                return lhs.time < rhs.time
            }

            return lhs.key < rhs.key
        }

        let limited = sorted.prefix(maxCount)

        return Array(limited)
    }

    private static func reminders(
        today: LocalDate,
        time: ReminderTime,
        recorded: Set<LocalDate>
    ) -> [PlannedNotification] {
        (0..<reminderDays)
            .map { today.adding(days: $0) }
            .filter { !recorded.contains($0) }
            .map { date in
                let message = ReminderMessage(on: date.weekday)

                return PlannedNotification(
                    key: "reminder",
                    date: date,
                    time: time,
                    title: message.title,
                    body: message.body,
                    route: .entry(date)
                )
            }
    }

    private static func notices(
        of recurring: Recurring,
        today: LocalDate,
        time: ReminderTime,
        names: [EntryCategory.ID: String],
        shortages: [Shortage]
    ) -> [PlannedNotification] {
        guard let daysBefore = recurring.remindDaysBefore else {
            return []
        }

        let category = recurring.categoryId.flatMap { names[$0] }
        let name = recurring.title(categoryName: category) ?? "固定費"
        let start = today.adding(days: daysBefore)
        let span = recurringDays - 1
        let end = start.adding(days: span)
        let usesCardBill = recurring.closingDay != nil

        return recurring.dates(from: start, through: end).map { date in
            let amount = usesCardBill ? nil : recurring.scheduledAmount(paidOn: date)
            let shortage = shortages.first { shortage in
                shortage.recurringId == recurring.id && shortage.date == date
            }

            let notifyDate = date.adding(days: -daysBefore)
            let text = body(amount: amount, on: date, daysBefore: daysBefore, shortage: shortage)

            return PlannedNotification(
                key: "recurring-\(recurring.id)",
                date: notifyDate,
                time: time,
                title: name,
                body: text,
                route: .recurring(recurring.id)
            )
        }
    }

    private static func body(
        amount: Int?,
        on date: LocalDate,
        daysBefore: Int,
        shortage: Shortage?
    ) -> String {
        guard let amount else {
            let bill = daysBefore == 0
                ? "今日は引き落としの日です"
                : "\(date.monthDayText) に引き落としがあります"

            guard let shortage else {
                return bill
            }

            let lack = "¥\(grouped(shortage.amount))"

            return "\(bill)。\(shortage.walletName)が \(lack) 足りません"
        }

        let yen = "¥\(grouped(amount))"

        if daysBefore == 0 {
            return "今日は \(yen) の日です"
        }

        return "\(date.monthDayText) に \(yen) です"
    }

    private static func grouped(_ amount: Int) -> String {
        let absolute = abs(amount)
        let digits = Array(String(absolute))

        var text = ""

        for (index, digit) in digits.enumerated() {
            if index > 0,
               (digits.count - index) % 3 == 0 {
                text.append(",")
            }

            text.append(digit)
        }

        return amount < 0 ? "-\(text)" : text
    }
}
