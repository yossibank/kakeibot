import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct ReminderModelTests {
    @Test
    func turnsOnAtEveningAndAsksPermission() async throws {
        let database = try AppDatabase.inMemory()
        let client = FakePermission(authorization: .notDetermined)
        let model = ReminderModel(
            database: database,
            today: LocalDate(Date(), in: .current),
            time: nil,
            permission: client.permission
        )
        await model.load()

        await model.setOn(true)
        let saved = try await database.setting(.reminderTime)
        let requested = await client.requested

        #expect(model.time == .evening)
        #expect(saved == .evening)
        #expect(requested)
        #expect(model.authorization == .allowed)
    }

    @Test
    func keepsChosenTimeWhenTurnedBackOn() async throws {
        let database = try AppDatabase.inMemory()
        let client = FakePermission(authorization: .allowed)
        let model = ReminderModel(
            database: database,
            today: LocalDate(Date(), in: .current),
            time: nil,
            permission: client.permission
        )
        let time = try #require(ReminderTime("22:30"))
        await model.load()

        await model.choose(time)
        await model.setOn(false)
        let cleared = try await database.setting(.reminderTime)
        await model.setOn(true)

        #expect(cleared == nil)
        #expect(model.time == time)
        #expect(model.isCustom)
    }

    @Test
    func showsDeniedOnlyWhenOn() async throws {
        let database = try AppDatabase.inMemory()
        let client = FakePermission(authorization: .denied)
        let model = ReminderModel(
            database: database,
            today: LocalDate(Date(), in: .current),
            time: nil,
            permission: client.permission
        )

        await model.load()
        let deniedWhileOff = model.isDenied
        await model.setOn(true)

        #expect(!deniedWhileOff)
        #expect(model.isDenied)
    }
}

extension ReminderModelTests {
    @Test
    func listsUpcomingRecurringNotices() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let today = try #require(LocalDate("2026-10-18"))
        let client = FakePermission(authorization: .allowed)

        let draft = RecurringDraft(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            memo: "家賃",
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: today,
            remindDaysBefore: 3
        )

        try await database.saveRecurring(draft, today: today, at: Date())
        let model = ReminderModel(
            database: database,
            today: today,
            time: nil,
            permission: client.permission
        )

        await model.load()
        let notice = try #require(model.upcomingNotices.first)

        #expect(model.upcomingNotices.count == 1)
        #expect(notice.title == "家賃")
        #expect(notice.date.description == "2026-10-24")
        #expect(notice.time == .morning)
    }
}

extension ReminderModelTests {
    actor FakePermission {
        private(set) var requested = false

        private var status: NotificationAuthorization

        nonisolated var permission: NotificationPermission {
            NotificationPermission {
                await self.status
            } request: {
                await self.request()
            }
        }

        init(authorization: NotificationAuthorization) {
            self.status = authorization
        }

        func request() -> Bool {
            requested = true

            if status == .notDetermined {
                status = .allowed
            }

            return status == .allowed
        }
    }
}
