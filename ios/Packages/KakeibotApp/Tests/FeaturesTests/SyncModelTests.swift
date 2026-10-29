import Features
import Foundation
import Store
import Testing

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
        let cloud = FakeCloud(isAvailable: false, hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.setOn(true)

        #expect(model.isOn == false)
        #expect(model.isAvailable == false)
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

extension SyncModelTests {
    actor FakeCloud {
        private(set) var deleted = false
        private(set) var shareCalls: [String] = []

        private let isAvailable: Bool
        private let hasData: Bool
        private let stopsInSheet: Bool
        private let failsToCreate: Bool
        private let failsToDelete: Bool

        init(
            isAvailable: Bool = true,
            hasData: Bool,
            stopsInSheet: Bool = false,
            failsToCreate: Bool = false,
            failsToDelete: Bool = false
        ) {
            self.isAvailable = isAvailable
            self.hasData = hasData
            self.stopsInSheet = stopsInSheet
            self.failsToCreate = failsToCreate
            self.failsToDelete = failsToDelete
        }
    }
}

extension SyncModelTests.FakeCloud {
    nonisolated var cloud: SyncCloud {
        SyncCloud {
            self.isAvailable
        } hasData: {
            self.hasData
        } deleteData: {
            await self.delete()
        } createShare: { _, _ in
            try await self.createShare()
        } showShare: { _, _, onStop in
            await self.record("show")

            if self.stopsInSheet {
                await onStop()
            }
        } deleteShare: { _ in
            try await self.deleteShare()
        }
    }

    func delete() {
        deleted = true
    }

    func record(_ call: String) {
        shareCalls.append(call)
    }

    func deleteShare() throws {
        shareCalls.append("delete")

        if failsToDelete {
            throw CancellationError()
        }
    }

    func createShare() throws {
        shareCalls.append("create")

        if failsToCreate {
            throw CancellationError()
        }
    }
}

private extension SyncModelTests {
    func wait(until isReady: () -> Bool) async throws {
        for _ in 0..<200 where !isReady() {
            try await Task.sleep(for: .milliseconds(10))
        }
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
