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
            permission: client.permission
        )
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
        let client = FakePermission(authorization: .allowed)
        let model = ReminderModel(
            database: database,
            permission: client.permission
        )
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
        let client = FakePermission(authorization: .denied)
        let model = ReminderModel(
            database: database,
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
