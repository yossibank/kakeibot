import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

extension SyncModelTests {
    @Test
    func leavesJoinedShareInICloudThenOnThisIPhone() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await joinShare(in: setup.database)

        await model.leave(item)
        let joined = try await joinedShares(in: setup.database)
        let wallets = try await setup.database.entryOptions().wallets

        #expect(await cloud.shareCalls == ["leave _owner"])
        #expect(joined.isEmpty)
        #expect(wallets.contains { $0.id == item.wallet.id } == false)
        #expect(model.state.notices.error.message == nil)
    }

    @Test
    func keepsTransferWithLeavingTime() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let left = Date(timeIntervalSince1970: 1_792_000_000)
        let model = SyncModel(
            parts: ScreenParts(database: setup.database, clock: .fixed(left)),
            cloud: cloud.cloud
        )
        let options = try await setup.database.entryOptions()
        let own = try #require(options.wallets.first)
        let shared = try #require(options.wallets.last)

        let draft = EntryDraft(
            type: .transfer,
            amount: 100,
            date: setup.today,
            categoryId: nil,
            walletId: own.id,
            toWalletId: shared.id
        )

        try await setup.database.saveEntry(draft, at: Date(timeIntervalSince1970: 1_791_000_000))
        let item = try await joinShare(in: setup.database)

        await model.leave(item)
        let entry = try #require(try setup.database.snapshot().entries.first)

        #expect(item.wallet.id == shared.id)
        #expect(entry.type == .expense)
        #expect(entry.updatedAt.timeIntervalSince1970 == left.timeIntervalSince1970)
    }

    @Test
    func staysInShareWhenLeavingICloudFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false, failsToLeave: true)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await joinShare(in: setup.database)

        await model.leave(item)
        let joined = try await joinedShares(in: setup.database)

        #expect(joined.map(\.wallet.id) == [item.wallet.id])
        #expect(model.state.notices.error.message == "共有から抜けられませんでした。時間をおいて試してください")
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
            owners: [zone: "_owner"],
            at: Date(timeIntervalSince1970: 1_791_000_000)
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
