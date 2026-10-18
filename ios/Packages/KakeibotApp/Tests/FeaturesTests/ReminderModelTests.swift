import Core
import Features
import Foundation
import Notifications
import Store
import Testing

@MainActor
struct ReminderModelTests {
    @Test
    func turnsOnAtEveningAndAsksPermission() async throws {
        let database = try AppDatabase.inMemory()
        let client = FakeCenter(authorization: .notDetermined)
        let model = ReminderModel(database: database, client: client)
        await model.load()

        await model.setOn(true)
        let saved = try await database.reminderTime()
        let requested = await client.requested

        #expect(model.time == .evening)
        #expect(saved == .evening)
        #expect(requested)
        #expect(model.authorization == .allowed)
    }

    @Test
    func keepsChosenTimeWhenTurnedBackOn() async throws {
        let database = try AppDatabase.inMemory()
        let client = FakeCenter(authorization: .allowed)
        let model = ReminderModel(database: database, client: client)
        let time = try #require(ReminderTime("22:30"))
        await model.load()

        await model.choose(time)
        await model.setOn(false)
        let cleared = try await database.reminderTime()
        await model.setOn(true)

        #expect(cleared == nil)
        #expect(model.time == time)
        #expect(model.isCustom)
    }

    @Test
    func showsDeniedOnlyWhenOn() async throws {
        let database = try AppDatabase.inMemory()
        let client = FakeCenter(authorization: .denied)
        let model = ReminderModel(database: database, client: client)

        await model.load()
        let deniedWhileOff = model.isDenied
        await model.setOn(true)

        #expect(!deniedWhileOff)
        #expect(model.isDenied)
    }
}

extension ReminderModelTests {
    actor FakeCenter: NotificationCenterClient {
        private(set) var requested = false

        private var status: NotificationAuthorization

        init(authorization: NotificationAuthorization) {
            self.status = authorization
        }

        func pendingIdentifiers() async -> [String] {
            []
        }

        func add(
            identifier: String,
            title: String,
            body: String,
            link: String,
            at components: DateComponents
        ) async throws {}

        func remove(_ identifiers: [String]) async {}

        func authorization() async -> NotificationAuthorization {
            status
        }

        func requestAuthorization() async -> Bool {
            requested = true
            status = .allowed
            return true
        }
    }
}
