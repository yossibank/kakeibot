import SwiftUI

public struct SyncCloud: Sendable {
    public let isAvailable: Check
    public let hasData: DataCheck
    public let deleteData: Delete

    public init(
        isAvailable: @escaping Check,
        hasData: @escaping DataCheck,
        deleteData: @escaping Delete
    ) {
        self.isAvailable = isAvailable
        self.hasData = hasData
        self.deleteData = deleteData
    }
}

public extension SyncCloud {
    typealias Check = @Sendable () async -> Bool
    typealias DataCheck = @Sendable () async throws -> Bool
    typealias Delete = @Sendable () async throws -> Void

    static let unavailable = Self {
        false
    } hasData: {
        false
    } deleteData: {}
}

public extension EnvironmentValues {
    @Entry var syncCloud: SyncCloud = .unavailable
}
