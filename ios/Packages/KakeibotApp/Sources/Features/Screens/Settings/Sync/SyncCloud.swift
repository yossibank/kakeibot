import Core
import Store
import SwiftUI

public struct SyncCloud: Sendable {
    public let account: Account
    public let summary: Summary
    public let deleteData: Delete
    public let createShare: CreateShare
    public let showShare: ShowShare
    public let participants: Participants
    public let deleteShare: DeleteShare
    public let leaveShare: LeaveShare

    public init(
        account: @escaping Account,
        summary: @escaping Summary,
        deleteData: @escaping Delete,
        createShare: @escaping CreateShare,
        showShare: @escaping ShowShare,
        participants: @escaping Participants,
        deleteShare: @escaping DeleteShare,
        leaveShare: @escaping LeaveShare
    ) {
        self.account = account
        self.summary = summary
        self.deleteData = deleteData
        self.createShare = createShare
        self.showShare = showShare
        self.participants = participants
        self.deleteShare = deleteShare
        self.leaveShare = leaveShare
    }
}

public extension SyncCloud {
    typealias Account = @Sendable () async -> SyncAccount
    typealias Summary = @Sendable () async throws -> SyncSummary?
    typealias Delete = @Sendable () async throws -> Void
    typealias CreateShare = @Sendable (Wallet.ID, String) async throws -> Void
    typealias Stop = @MainActor () async -> Void
    typealias Fail = @MainActor () -> Void
    typealias ShowShare = @MainActor (
        Wallet.ID,
        String,
        @escaping Stop,
        @escaping Fail
    ) async throws
        -> Void
    typealias Participants = @Sendable (Wallet.ID, String) async throws -> [SyncParticipant]
    typealias DeleteShare = @Sendable (Wallet.ID) async throws -> Void
    typealias LeaveShare = @Sendable (Wallet.ID, String) async throws -> Void

    static let unavailable = Self(
        account: {
            .noAccount
        },
        summary: {
            nil
        },
        deleteData: {},
        createShare: { _, _ in },
        showShare: { _, _, _, _ in },
        participants: { _, _ in
            []
        },
        deleteShare: { _ in },
        leaveShare: { _, _ in }
    )
}

public extension EnvironmentValues {
    @Entry var syncCloud: SyncCloud = .unavailable
}
