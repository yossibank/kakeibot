import Core
import SwiftUI

public struct SyncCloud: Sendable {
    public let isAvailable: Check
    public let hasData: DataCheck
    public let deleteData: Delete
    public let createShare: CreateShare
    public let showShare: ShowShare
    public let deleteShare: DeleteShare

    public init(
        isAvailable: @escaping Check,
        hasData: @escaping DataCheck,
        deleteData: @escaping Delete,
        createShare: @escaping CreateShare,
        showShare: @escaping ShowShare,
        deleteShare: @escaping DeleteShare
    ) {
        self.isAvailable = isAvailable
        self.hasData = hasData
        self.deleteData = deleteData
        self.createShare = createShare
        self.showShare = showShare
        self.deleteShare = deleteShare
    }
}

public extension SyncCloud {
    typealias Check = @Sendable () async -> Bool
    typealias DataCheck = @Sendable () async throws -> Bool
    typealias Delete = @Sendable () async throws -> Void
    typealias CreateShare = @Sendable (Wallet.ID, String) async throws -> Void
    typealias Stop = @MainActor () async -> Void
    typealias ShowShare = @MainActor (Wallet.ID, String, @escaping Stop) async throws -> Void
    typealias DeleteShare = @Sendable (Wallet.ID) async throws -> Void

    static let unavailable = Self(
        isAvailable: {
            false
        },
        hasData: {
            false
        },
        deleteData: {},
        createShare: { _, _ in },
        showShare: { _, _, _ in },
        deleteShare: { _ in }
    )
}

public extension EnvironmentValues {
    @Entry var syncCloud: SyncCloud = .unavailable
}
