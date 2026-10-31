@testable import AppFeature
import Features
import Store
import Testing

@MainActor
extension AppModelTests {
    @Test
    func unlocksProFromStatus() async throws {
        let database = try AppDatabase.inMemory()
        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .unlocked))

        await model.observePro(in: database)

        #expect(model.isPro)
    }

    @Test
    func keepsProOffWhenLocked() async throws {
        let database = try AppDatabase.inMemory()
        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .locked))

        await model.observePro(in: database)

        #expect(!model.isPro)
    }

    @Test
    func appliesUpdatesInOrder() async throws {
        let database = try AppDatabase.inMemory()

        let model = AppModel(
            openDatabase: { database },
            proStore: .stub(status: .locked, updates: [.unlocked, .revoked, .unlocked])
        )

        await model.observePro(in: database)

        #expect(model.isPro)
    }

    @Test
    func turnsOffSyncWhenRevoked() async throws {
        let database = try AppDatabase.inMemory()
        try await database.turnOnSync()
        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .revoked))

        await model.observePro(in: database)

        #expect(try await database.isSyncEnabled() == false)
        #expect(!model.isPro)
        #expect(model.notice.message == nil)
    }

    @Test
    func turnsOffSyncWhenRevokedByUpdate() async throws {
        let database = try AppDatabase.inMemory()
        try await database.turnOnSync()

        let model = AppModel(
            openDatabase: { database },
            proStore: .stub(status: .unlocked, updates: [.revoked])
        )

        await model.observePro(in: database)

        #expect(try await database.isSyncEnabled() == false)
        #expect(!model.isPro)
    }

    @Test
    func leavesSyncOffWhenRevoked() async throws {
        let database = try AppDatabase.inMemory()
        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .revoked))

        await model.observePro(in: database)

        #expect(try await database.isSyncEnabled() == false)
        #expect(!model.isPro)
        #expect(model.notice.message == nil)
    }

    @Test
    func keepsSyncOnWhenLocked() async throws {
        let database = try AppDatabase.inMemory()
        try await database.turnOnSync()
        let model = AppModel(openDatabase: { database }, proStore: .stub(status: .locked))

        await model.observePro(in: database)

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
