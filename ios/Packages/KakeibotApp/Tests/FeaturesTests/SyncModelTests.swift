import Features
import Foundation
import Store
import Testing
import TestSupport

@MainActor
struct SyncModelTests {
    @Test
    func sendsLocalDataWhenCloudIsEmpty() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.setOn(true)

        #expect(model.isOn)
        #expect(model.isChoosing == false)
        #expect(try await setup.database.pendingSyncChanges().isEmpty == false)
    }

    @Test
    func usesCloudDataWithoutAskingWhenNoEntries() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.setOn(true)

        #expect(model.isOn)
        #expect(model.isChoosing == false)
        #expect(try await setup.database.pendingSyncChanges().isEmpty)
    }

    @Test
    func asksWhichDataToUseWhenBothHaveData() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.setOn(true)

        #expect(model.isOn == false)
        #expect(model.isChoosing)

        await model.useLocalData()

        #expect(model.isOn)
        #expect(await cloud.deleted)
        #expect(try await setup.database.hasEntries())
    }

    @Test
    func staysOffWhenSignedOut() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(account: .noAccount, hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.setOn(true)

        #expect(model.isOn == false)
        #expect(model.isAvailable == false)
    }

    @Test(
        arguments: [
            (SyncAccount.noAccount, "設定アプリで iCloud にサインインすると使えます"),
            (.restricted, "この iPhone では、制限で iCloud を使えません"),
            (.temporarilyUnavailable, "設定アプリで iCloud にサインインし直すと使えます"),
            (.couldNotDetermine, "iCloud の状態を確かめられませんでした。時間をおいて開き直してください")
        ]
    )
    func explainsWhyICloudCannotBeUsed(
        account: SyncAccount,
        expected: String
    ) async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(account: account, hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.load()

        #expect(model.footnote == expected)
    }

    @Test
    func checksICloudAgainWhenBack() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(account: .noAccount, hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.load()
        await cloud.signIn()
        await model.refreshAccount()

        #expect(model.isAvailable)
        #expect(model.footnote == "オンにすると、ほかの端末と記録がそろいます")
    }

    @Test
    func turnsOff() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.setOn(true)
        await model.setOn(false)

        #expect(model.isOn == false)
        #expect(try await setup.database.pendingSyncChanges().isEmpty)
    }

    @Test
    func showsWhySyncStoppedOnItsOwn() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        try await setup.database.turnOnSync()

        let task = Task {
            await model.observe()
        }

        try await wait {
            model.isOn
        }

        try await setup.database.turnOffSyncForAccountChange(.signedOut)

        try await wait {
            model.stopReason != nil
        }

        task.cancel()

        #expect(model.isOn == false)
        #expect(model.stopReason?.message == "iCloud からサインアウトしたため、同期が切れました")
    }

    @Test
    func clearsWhySyncStoppedWhenTurnedOnAgain() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        try await setup.database.turnOnSync()
        try await setup.database.turnOffSync(because: .cloudReplaced)

        let task = Task {
            await model.observe()
        }

        try await wait {
            model.stopReason != nil
        }

        await model.setOn(true)

        try await wait {
            model.stopReason == nil
        }

        task.cancel()

        #expect(model.isOn)
        #expect(model.stopReason == nil)
    }
}

extension SyncModelTests {
    func wait(
        sourceLocation: SourceLocation = #_sourceLocation,
        until isReady: @escaping @MainActor () -> Bool
    ) async throws {
        await ObservationWait.until(
            sourceLocation: sourceLocation,
            isReady
        )
    }

    func firstShare(in database: AppDatabase) async throws -> WalletShare {
        var first: WalletShare?

        for try await shares in database.walletShareUpdates() {
            first = shares.first
            break
        }

        return try #require(first)
    }
}
