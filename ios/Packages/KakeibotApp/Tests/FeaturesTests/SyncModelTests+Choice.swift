import Features
import Foundation
import Store
import Testing

extension SyncModelTests {
    @Test
    func showsBothSummariesWhenAsking() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloudSummary = SyncSummary(entryCount: 12, updatedAt: Date.distantFuture)
        let cloud = FakeCloud(hasData: true, cloudSummary: cloudSummary)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.setOn(true)

        let choice = try #require(model.choice)
        #expect(choice.local.entryCount == 1)
        #expect(choice.cloud == cloudSummary)
        #expect(choice.newer == .cloud)
    }

    @Test
    func showsOnWhileAsking() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.setOn(true)

        #expect(model.isOn == false)
        #expect(model.shownOn)
    }

    @Test
    func showsOffAfterCancellingTheChoice() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        await model.setOn(true)

        model.cancelChoice()

        #expect(model.isChoosing == false)
        #expect(model.shownOn == false)
        #expect(try await setup.database.isSyncEnabled() == false)
        #expect(await cloud.deleted == false)
    }

    @Test
    func showsOffWhenSignedOutOnTurningOn() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(account: .noAccount, hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.setOn(true)

        #expect(model.shownOn == false)
    }

    @Test
    func showsOnAfterUsingCloudData() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        await model.setOn(true)

        await model.useCloudData()

        #expect(model.isChoosing == false)
        #expect(model.isOn)
        #expect(model.shownOn)
    }

    @Test
    func showsOffWhenCheckingCloudFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: true, failsToSummarize: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        await model.setOn(true)

        #expect(model.shownOn == false)
        #expect(model.errorNotice.message != nil)
    }

    @Test
    func showsOnWhenTurningOffFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        await model.setOn(true)
        try await setup.database.failWrites(to: "sync_state")

        await model.setOn(false)

        #expect(model.shownOn)
        #expect(model.errorNotice.message != nil)
    }

    @Test
    func showsOffWhenUsingCloudDataFails() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        await model.setOn(true)
        try await setup.database.failWrites(to: "sync_state")

        await model.useCloudData()

        #expect(model.isChoosing == false)
        #expect(model.shownOn == false)
    }

    @Test
    func showsOffWhenDeletingCloudDataFails() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true, failsToDeleteData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        await model.setOn(true)

        await model.useLocalData()

        #expect(model.shownOn == false)
        #expect(try await setup.database.isSyncEnabled() == false)
    }

    @Test
    func showsOnAfterUsingLocalData() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        await model.setOn(true)

        await model.useLocalData()

        #expect(model.shownOn)
    }

    @Test
    func usesOnlyTheFirstChoice() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        await model.setOn(true)

        await model.useCloudData()
        await model.useLocalData()

        #expect(model.isOn)
        #expect(await cloud.deleted == false)
    }

    @Test
    func refusesAnotherRequestWhileSwitching() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)

        let first = model.request(true)
        let second = model.request(false)

        #expect(first)
        #expect(second == false)
        #expect(model.shownOn)
    }
}
