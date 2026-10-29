import Features
import Foundation
import Store
import Testing

extension SyncModelTests {
    @Test
    func leavesJoinedShareInICloudThenOnThisIPhone() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        let item = try await joinShare(in: setup.database)

        await model.leave(item)
        let joined = try await joinedShares(in: setup.database)
        let wallets = try await setup.database.entryOptions().wallets

        #expect(await cloud.shareCalls == ["leave _owner"])
        #expect(joined.isEmpty)
        #expect(wallets.contains { $0.id == item.wallet.id } == false)
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func staysInShareWhenLeavingICloudFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false, failsToLeave: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        let item = try await joinShare(in: setup.database)

        await model.leave(item)
        let joined = try await joinedShares(in: setup.database)

        #expect(joined.map(\.wallet.id) == [item.wallet.id])
        #expect(model.errorNotice.message == "共有から抜けられませんでした。時間をおいて試してください")
    }
}

private extension SyncModelTests {
    func joinShare(in database: AppDatabase) async throws -> JoinedShare {
        let wallet = try #require(try await database.entryOptions().wallets.last)
        let zone = SyncZone.wallet(wallet.id)
        let key = SyncKey(table: .wallet, id: wallet.id.description)
        let id = SyncRecordID(key: key, zoneName: zone)

        try await database.applySyncChanges(
            saved: [],
            deleted: [],
            systemFields: [id: Data([1])],
            owners: [zone: "_owner"]
        )

        return try #require(try await joinedShares(in: database).first)
    }

    func joinedShares(in database: AppDatabase) async throws -> [JoinedShare] {
        for try await shares in database.joinedShareUpdates() {
            return shares
        }

        return []
    }
}
