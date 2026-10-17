import Core
import Foundation
import Testing

struct NotificationPlanTests {
    @Test(arguments: try planCases)
    func plansNotifications(fixture: PlanCase) {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let recurrings = fixture.recurrings.map { row in
            Recurring(
                type: .expense,
                amount: row.amount,
                categoryId: EntryCategory.ID(),
                walletId: Wallet.ID(),
                memo: row.name,
                frequency: row.frequency,
                month: row.month,
                day: row.day,
                startDate: row.startDate,
                endDate: row.endDate,
                remindDaysBefore: row.remindDaysBefore,
                createdAt: now,
                updatedAt: now
            )
        }

        let notifications = NotificationPlan.notifications(
            today: fixture.today,
            reminderTime: fixture.reminderTime,
            recordedDates: Set(fixture.recorded),
            recurrings: recurrings,
            names: [:]
        )

        let rows = notifications.map { notification in
            Expected(
                date: notification.date,
                time: notification.time,
                title: notification.title,
                body: notification.body
            )
        }

        #expect(rows == fixture.notifications)
    }

    @Test
    func readsAndWritesTime() throws {
        let time = try #require(ReminderTime("07:05"))

        #expect(time.hour == 7)
        #expect(time.minute == 5)
        #expect(time.description == "07:05")
        #expect(ReminderTime("7:05") == nil)
        #expect(ReminderTime("24:00") == nil)
    }
}

extension NotificationPlanTests {
    struct PlanCase: Decodable, Sendable {
        let today: LocalDate
        let reminderTime: ReminderTime?
        let recorded: [LocalDate]
        let recurrings: [RecurringRow]
        let notifications: [Expected]
    }

    struct RecurringRow: Decodable, Sendable {
        let name: String
        let amount: Int
        let frequency: Recurring.Frequency
        let month: Int?
        let day: Int
        let startDate: LocalDate
        let endDate: LocalDate?
        let remindDaysBefore: Int?
    }

    struct Expected: Decodable, Equatable, Sendable {
        let date: LocalDate
        let time: ReminderTime
        let title: String
        let body: String
    }
}

private extension NotificationPlanTests {
    static var planCases: [PlanCase] {
        get throws {
            try Fixture.load("notification/notification-plan.json")
        }
    }
}
