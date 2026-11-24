import Core
import FeatureModels
import Features
import Store
import Testing

extension SyncModelTests {
    @Test
    func asksBeforeSharingAWallet() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await firstShare(in: setup.database)

        await model.open(item)
        let after = try await firstShare(in: setup.database)

        #expect(model.state.invitation == item)
        #expect(await cloud.shareCalls.isEmpty)
        #expect(after.isShared == false)
    }

    @Test
    func startsSharingAndShowsSheetAfterConfirming() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await firstShare(in: setup.database)

        await model.open(item)
        await model.confirmInvitation()
        let shared = try await firstShare(in: setup.database)

        #expect(await cloud.shareCalls == ["create", "show"])
        #expect(shared.isShared)
        #expect(model.state.invitation == nil)
        #expect(model.state.workingWallet == nil)
        #expect(model.state.errorNotice.message == nil)
    }

    @Test
    func leavesWalletAloneWhenInvitationIsCancelled() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await firstShare(in: setup.database)

        await model.open(item)
        model.cancelInvitation()
        await model.confirmInvitation()

        #expect(model.state.invitation == nil)
        #expect(await cloud.shareCalls.isEmpty)
    }

    @Test
    func showsWhoIsInASharedWallet() async throws {
        let setup = try await HomeModelTests.Setup()
        let members = [
            SyncParticipant(name: "自分", state: .owner),
            SyncParticipant(name: "家族", state: .invited)
        ]
        let cloud = FakeCloud(hasData: false, participants: members)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await sharedItem(in: setup.database)

        await model.open(item)

        #expect(model.state.opened == item)
        #expect(model.output.participants == members)
        #expect(model.output.isParticipantsFailed == false)
        #expect(await cloud.shareCalls == ["list"])
    }

    @Test
    func tellsWhenMembersCannotBeLoaded() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false, failsToList: true)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await sharedItem(in: setup.database)

        await model.open(item)

        #expect(model.output.participants == nil)
        #expect(model.output.isParticipantsFailed)
    }

    @Test
    func invitesMoreWithoutCreatingAgain() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await sharedItem(in: setup.database)

        await model.open(item)
        await model.inviteMore()

        #expect(await cloud.shareCalls == ["list", "show"])
        #expect(model.state.opened == nil)
    }

    @Test
    func stopsSharingInICloudThenOnThisIPhone() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await sharedItem(in: setup.database)

        await model.stopSharing(item)
        let after = try await firstShare(in: setup.database)

        #expect(await cloud.shareCalls == ["delete"])
        #expect(after.isShared == false)
        #expect(model.state.workingWallet == nil)
    }

    @Test
    func endsSharingWhenSheetStops() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false, stopsInSheet: true)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await firstShare(in: setup.database)

        await model.open(item)
        await model.confirmInvitation()
        let after = try await firstShare(in: setup.database)

        #expect(await cloud.shareCalls == ["create", "show", "delete"])
        #expect(after.isShared == false)
    }

    @Test
    func tellsWhenSheetCannotSaveInvitation() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false, failsInSheet: true)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await sharedItem(in: setup.database)

        await model.open(item)
        await model.inviteMore()

        #expect(model.state.errorNotice.message == "招待を保存できませんでした。時間をおいて試してください")
    }

    @Test
    func keepsWalletUnsharedWhenCreatingFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false, failsToCreate: true)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await firstShare(in: setup.database)

        await model.open(item)
        await model.confirmInvitation()
        let after = try await firstShare(in: setup.database)

        #expect(after.isShared == false)
        #expect(model.state.workingWallet == nil)
        #expect(model.state.errorNotice.message == "共有を開けませんでした。時間をおいて試してください")
    }

    @Test
    func keepsSharingWhenDeletingCloudShareFails() async throws {
        let setup = try await HomeModelTests.Setup()
        let cloud = FakeCloud(hasData: false, failsToDelete: true)
        let model = SyncModel(parts: .system(setup.database), cloud: cloud.cloud)
        let item = try await sharedItem(in: setup.database)

        await model.stopSharing(item)
        let after = try await firstShare(in: setup.database)

        #expect(after.isShared)
        #expect(model.state.errorNotice.message == "共有を終えられませんでした。時間をおいて試してください")
    }
}

private extension SyncModelTests {
    func sharedItem(in database: AppDatabase) async throws -> WalletShare {
        let item = try await firstShare(in: database)

        try await database.startSharing(item.wallet.id)

        return try await firstShare(in: database)
    }
}
