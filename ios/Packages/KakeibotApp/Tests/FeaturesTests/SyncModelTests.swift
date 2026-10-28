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
}

extension SyncModelTests {
    actor FakeCloud {
        private(set) var deleted = false

        private let isAvailable: Bool
        private let hasData: Bool

        nonisolated var cloud: SyncCloud {
            SyncCloud {
                self.isAvailable
            } hasData: {
                self.hasData
            } deleteData: {
                await self.delete()
            }
        }

        init(
            isAvailable: Bool = true,
            hasData: Bool
        ) {
            self.isAvailable = isAvailable
            self.hasData = hasData
        }

        func delete() {
            deleted = true
        }
    }
}
