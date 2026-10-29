import Features
import Testing

extension SyncModelTests {
    @Test
    func staysOffAfterDeletingCloudWhenTurningOnFails() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        await model.setOn(true)
        try await setup.database.failWrites(to: "sync_state")

        await model.useLocalData()

        #expect(await cloud.deleted)
        #expect(model.isOn == false)
        #expect(model.isWorking == false)
        #expect(model.errorNotice.message == "同期を切り替えられませんでした。時間をおいて試してください")
        #expect(try await setup.database.isSyncEnabled() == false)
    }

    @Test
    func keepsLocalDataWhenUsingCloudFails() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        let cloud = FakeCloud(hasData: true)
        let model = SyncModel(database: setup.database, cloud: cloud.cloud)
        await model.setOn(true)
        try await setup.database.failWrites(to: "sync_state")

        await model.useCloudData()

        #expect(model.isOn == false)
        #expect(model.errorNotice.message == "同期を切り替えられませんでした。時間をおいて試してください")
        #expect(try await setup.database.hasEntries())
        #expect(await cloud.deleted == false)
    }
}
