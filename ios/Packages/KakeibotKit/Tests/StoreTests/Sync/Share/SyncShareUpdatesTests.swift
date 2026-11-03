import Core
import Foundation
@testable import Store
import Testing

@Suite(.timeLimit(.minutes(1)))
struct SyncShareUpdatesTests {
    @Test
    func showsSharingAsSoonAsItStarts() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        var updates = setup.database.walletShareUpdates().makeAsyncIterator()

        let before = try await updates.next()
        try await setup.database.startSharing(id)
        let after = try await updates.next()

        #expect(before?.first { $0.wallet.id == id }?.isShared == false)
        #expect(after?.first { $0.wallet.id == id }?.isShared == true)
    }

    @Test
    func showsStoppedSharingAsSoonAsItEnds() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        try await setup.database.startSharing(id)
        var updates = setup.database.walletShareUpdates().makeAsyncIterator()

        let before = try await updates.next()
        try await setup.database.endSharing(id)
        let after = try await updates.next()

        #expect(before?.first { $0.wallet.id == id }?.isShared == true)
        #expect(after?.first { $0.wallet.id == id }?.isShared == false)
    }

    @Test
    func showsJoinedWalletAsSoonAsItArrives() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        var updates = setup.database.joinedShareUpdates().makeAsyncIterator()

        let before = try await updates.next()
        try await setup.joinForeignShare(of: walletID)
        let after = try await updates.next()

        #expect(before?.isEmpty == true)
        #expect(after?.map(\.wallet.id.description) == [walletID])
    }

    @Test
    func showsSharingEndedWhenAccountChanges() async throws {
        let setup = try await SyncTests.Setup()
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        try await setup.database.startSharing(id)
        var updates = setup.database.walletShareUpdates().makeAsyncIterator()

        let before = try await updates.next()
        try await setup.database.turnOffSyncForAccountChange(.accountChanged)
        let after = try await updates.next()

        #expect(before?.first { $0.wallet.id == id }?.isShared == true)
        #expect(after?.first { $0.wallet.id == id }?.isShared == false)
    }

    @Test
    func startsSyncActivityWhenSharingStarts() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        var updates = setup.database.syncActivityUpdates().makeAsyncIterator()

        let before = try await updates.next()
        try await setup.database.startSharing(id)
        let after = try await updates.next()

        #expect(before?.isSharing == false)
        #expect(after?.isSharing == true)
    }
}
