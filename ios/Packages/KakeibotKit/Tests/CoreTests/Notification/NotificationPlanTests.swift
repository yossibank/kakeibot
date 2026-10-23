import Core
import Foundation
import Testing

struct NotificationPlanTests {
    @Test(arguments: try planCases)
    func plansNotifications(fixture: PlanCase) {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let recurrings = fixture.recurrings.map { row in
            let isBill = row.closingDay != nil

            return Recurring(
                type: isBill ? .transfer : .expense,
                amount: row.amount,
                categoryId: isBill ? nil : EntryCategory.ID(),
                walletId: Wallet.ID(),
                toWalletId: isBill ? Wallet.ID() : nil,
                memo: row.name,
                frequency: row.frequency,
                month: row.month,
                day: row.day,
                closingDay: row.closingDay,
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
            names: [:],
            shortages: Self.shortages(of: fixture, recurrings: recurrings)
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

    @Test
    func readsAndWritesLink() throws {
        let date = try #require(LocalDate("2026-10-18"))
        let id = Recurring.ID()
        let entry = PlannedNotification.Route.entry(date)
        let recurring = PlannedNotification.Route.recurring(id)
        let template = PlannedNotification.Route.template(EntryTemplate.ID())

        #expect(entry.link == "entry/2026-10-18")
        #expect(PlannedNotification.Route(link: entry.link) == entry)
        #expect(PlannedNotification.Route(link: recurring.link) == recurring)
        #expect(PlannedNotification.Route(link: template.link) == template)
        #expect(PlannedNotification.Route(link: "template/x") == nil)
        #expect(PlannedNotification.Route(link: "entry/2026-13-01") == nil)
        #expect(PlannedNotification.Route(link: "budget/1") == nil)
        #expect(PlannedNotification.Route(link: "entry") == nil)
    }

    @Test
    func readsAndWritesURL() throws {
        let date = try #require(LocalDate("2026-10-18"))
        let home = PlannedNotification.Route.home
        let entry = PlannedNotification.Route.entry(date)
        let homeURL = try #require(home.url)
        let entryURL = try #require(entry.url)
        let other = try #require(URL(string: "https://example.com/home"))

        #expect(homeURL.absoluteString == "kakeibot://home")
        #expect(entryURL.absoluteString == "kakeibot://entry/2026-10-18")
        #expect(PlannedNotification.Route(url: homeURL) == home)
        #expect(PlannedNotification.Route(url: entryURL) == entry)
        #expect(PlannedNotification.Route(url: other) == nil)
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
        let closingDay: Int?
        let startDate: LocalDate
        let endDate: LocalDate?
        let remindDaysBefore: Int?
        let shortage: ShortageRow?
    }

    struct ShortageRow: Decodable, Sendable {
        let date: LocalDate
        let wallet: String
        let amount: Int
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

    static func shortages(
        of fixture: PlanCase,
        recurrings: [Recurring]
    ) -> [NotificationPlan.Shortage] {
        zip(fixture.recurrings, recurrings).compactMap { row, recurring in
            row.shortage.map { shortage in
                NotificationPlan.Shortage(
                    recurringId: recurring.id,
                    date: shortage.date,
                    walletName: shortage.wallet,
                    amount: shortage.amount
                )
            }
        }
    }
}
