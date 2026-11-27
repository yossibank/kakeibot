@testable import AppFeature
import FeatureModels
import Features
import Store
import Testing

@MainActor
extension AppModelTests {
    @Test
    func unlocksProFromStatus() async throws {
        let database = try AppDatabase.inMemory()
        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .unlocked))

        await model.open()
        await model.observePro()

        #expect(model.input.isPro)
    }

    @Test
    func keepsProOffWhenLocked() async throws {
        let database = try AppDatabase.inMemory()
        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .locked))

        await model.open()
        await model.observePro()

        #expect(!model.input.isPro)
    }

    @Test
    func appliesUpdatesInOrder() async throws {
        let database = try AppDatabase.inMemory()

        let model = AppModel(
            openDatabase: { database },
            proStore: .stub(status: .locked, updates: [.unlocked, .revoked, .unlocked])
        )

        await model.open()
        await model.observePro()

        #expect(model.input.isPro)
    }

    @Test
    func turnsOffSyncWhenRevoked() async throws {
        let database = try AppDatabase.inMemory()
        try await database.turnOnSync()
        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .revoked))

        await model.open()
        await model.observePro()

        #expect(try await database.isSyncEnabled() == false)
        #expect(!model.input.isPro)
        #expect(model.state.notices.error.message == nil)
    }

    @Test
    func turnsOffSyncWhenRevokedByUpdate() async throws {
        let database = try AppDatabase.inMemory()
        try await database.turnOnSync()

        let model = AppModel(
            openDatabase: { database },
            proStore: .stub(status: .unlocked, updates: [.revoked])
        )

        await model.open()
        await model.observePro()

        #expect(try await database.isSyncEnabled() == false)
        #expect(!model.input.isPro)
    }

    @Test
    func leavesSyncOffWhenRevoked() async throws {
        let database = try AppDatabase.inMemory()
        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .revoked))

        await model.open()
        await model.observePro()

        #expect(try await database.isSyncEnabled() == false)
        #expect(!model.input.isPro)
        #expect(model.state.notices.error.message == nil)
    }

    @Test
    func showsNoticeWhenSyncFailsToStop() async throws {
        let database = try AppDatabase.inMemory()
        try await database.turnOnSync()

        try await database.writer.write { db in
            try db.execute(
                sql: """
                CREATE TRIGGER fail_sync_state BEFORE UPDATE ON sync_state
                BEGIN SELECT RAISE(ABORT, 'failing for tests'); END
                """
            )
        }

        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .revoked))

        await model.open()
        await model.observePro()

        #expect(try await database.isSyncEnabled())
        #expect(!model.input.isPro)
        #expect(model.state.notices.error.message == "同期を止められませんでした。設定の「同期と共有」から止めてください")
    }

    @Test
    func keepsSyncOnWhenLocked() async throws {
        let database = try AppDatabase.inMemory()
        try await database.turnOnSync()
        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .locked))

        await model.open()
        await model.observePro()

        #expect(try await database.isSyncEnabled())
    }
}

private extension ProStore {
    static func stub(
        status: ProStatus,
        updates: [ProStatus] = []
    ) -> Self {
        Self(
            status: {
                status
            },
            updates: {
                AsyncStream { continuation in
                    for update in updates {
                        continuation.yield(update)
                    }

                    continuation.finish()
                }
            },
            price: {
                throw ProStoreError.unavailable
            },
            purchase: {
                .locked
            },
            restore: {
                .locked
            }
        )
    }
}
