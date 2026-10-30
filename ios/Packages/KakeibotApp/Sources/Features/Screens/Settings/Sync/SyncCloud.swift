import Core
import Store
import SwiftUI

public struct SyncCloud: Sendable {
    public let account: Account
    public let summary: Summary
    public let deleteData: Delete
    public let createShare: CreateShare
    public let showShare: ShowShare
    public let deleteShare: DeleteShare
    public let leaveShare: LeaveShare

    public init(
        account: @escaping Account,
        summary: @escaping Summary,
        deleteData: @escaping Delete,
        createShare: @escaping CreateShare,
        showShare: @escaping ShowShare,
        deleteShare: @escaping DeleteShare,
        leaveShare: @escaping LeaveShare
    ) {
        self.account = account
        self.summary = summary
        self.deleteData = deleteData
        self.createShare = createShare
        self.showShare = showShare
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
    typealias ShowShare = @MainActor (Wallet.ID, String, @escaping Stop) async throws -> Void
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
        showShare: { _, _, _ in },
        deleteShare: { _ in },
        leaveShare: { _, _ in }
    )
}

public extension EnvironmentValues {
    @Entry var syncCloud: SyncCloud = .unavailable
}
