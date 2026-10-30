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
        #expect(model.footnote == "切っても、この iPhone のデータは残ります")
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
            await model.observeStatus()
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
            await model.observeStatus()
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

    @Test
    func explainsWhySendingIsStuck() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        try await setup.database.turnOnSync()

        let task = Task {
            await model.observeStatus()
        }

        try await setup.database.setSyncSendProblem(.quotaExceeded)

        try await wait {
            model.sendProblem != nil
        }

        task.cancel()

        #expect(model.pendingText(3) == "iCloud の容量が足りず、送れていません（残り 3 件）")
        #expect(model.pendingText(0) == "最新の状態です")
    }

    @Test
    func showsSendingWhileNothingIsStuck() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        #expect(model.pendingText(3) == "iCloud に送っています（残り 3 件）")
    }

    @Test
    func startsSharingAndShowsSheet() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        let item = try await firstShare(in: setup.database)

        await model.share(item)
        let shared = try await firstShare(in: setup.database)

        #expect(await cloud.shareCalls == ["create", "show"])
        #expect(shared.isShared)
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func showsSheetWithoutCreatingWhenAlreadyShared() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        let item = try await firstShare(in: setup.database)

        try await setup.database.startSharing(item.wallet.id)
        let shared = try await firstShare(in: setup.database)
        await model.share(shared)

        #expect(await cloud.shareCalls == ["show"])
    }

    @Test
    func endsSharingWhenSheetStops() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false, stopsInSheet: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        let item = try await firstShare(in: setup.database)

        await model.share(item)
        let after = try await firstShare(in: setup.database)

        #expect(await cloud.shareCalls == ["create", "show", "delete"])
        #expect(after.isShared == false)
    }

    @Test
    func keepsWalletUnsharedWhenCreatingFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false, failsToCreate: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        let item = try await firstShare(in: setup.database)

        await model.share(item)
        let after = try await firstShare(in: setup.database)

        #expect(after.isShared == false)
        #expect(model.errorNotice.message != nil)
    }

    @Test
    func keepsSharingWhenDeletingCloudShareFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false, stopsInSheet: true, failsToDelete: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        let item = try await firstShare(in: setup.database)

        await model.share(item)
        let after = try await firstShare(in: setup.database)

        #expect(after.isShared == true)
        #expect(model.errorNotice.message != nil)
    }
}

private extension SyncModelTests {
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
