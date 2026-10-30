import Features
import Foundation
import Store
import Testing

extension SyncModelTests {
    @Test
    func showsReceivingUntilFirstFetchEnds() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        let syncedAt = Date(timeIntervalSince1970: 1_793_000_000)

        let task = Task {
            await model.observe()
        }

        await model.setOn(true)

        try await wait {
            model.progress == .receiving
        }

        let changes = try await setup.database.pendingSyncChanges()
        try await setup.database.removeSyncChanges(changes)
        try await setup.database.setSyncFetching(false)
        try await setup.database.setSyncedAt(syncedAt)

        try await wait {
            model.progress == .upToDate(syncedAt)
        }

        task.cancel()

        #expect(model.progress?.isBusy == false)
    }

    @Test
    func showsHowManyAreLeftToSend() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        try await setup.database.turnOnSync()
        try await setup.database.setSyncFetching(false)
        let count = try await setup.database.pendingSyncChanges().count

        let task = Task {
            await model.observe()
        }

        try await wait {
            model.progress == .sending(count)
        }

        try await setup.database.setSyncSendProblem(.quotaExceeded)

        try await wait {
            model.progress == .stuck(.quotaExceeded, count)
        }

        task.cancel()

        #expect(model.progress?.isProblem == true)
    }

    @Test
    func showsNothingWhileOffByHand() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        let task = Task {
            await model.observe()
        }

        await model.setOn(true)
        await model.setOn(false)

        try await wait {
            model.isOn == false && model.pendingCount != nil
        }

        task.cancel()

        #expect(model.progress == nil)
        #expect(model.footnote == "オンにすると、ほかの端末と記録がそろいます")
    }

    @Test
    func showsWhySyncStoppedInsteadOfProgress() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        try await setup.database.turnOnSync()
        try await setup.database.turnOffSync(because: .cloudReplaced)

        let task = Task {
            await model.observe()
        }

        try await wait {
            model.progress == .stopped(.cloudReplaced)
        }

        task.cancel()

        #expect(model.progress?.isProblem == true)
    }

    @Test
    func explainsEachStep() {
        let syncedAt = Date(timeIntervalSince1970: 1_793_000_000)
        let time = syncedAt.formatted(.dateTime.hour().minute())

        #expect(SyncProgress.switching.message == "切り替えています…")
        #expect(SyncProgress.checking.message == "iCloud の状態を確かめています…")
        #expect(SyncProgress.receiving.message == "iCloud から受け取っています…")
        #expect(SyncProgress.sending(3).message == "iCloud に送っています（残り 3 件）")
        #expect(
            SyncProgress.stuck(.quotaExceeded, 3).message
                == "iCloud の容量が足りず、送れていません（残り 3 件）"
        )
        #expect(SyncProgress.upToDate(nil).message == "最新の状態です")
        #expect(SyncProgress.upToDate(syncedAt).message == "最新の状態です（\(time) に同期）")
    }
}
