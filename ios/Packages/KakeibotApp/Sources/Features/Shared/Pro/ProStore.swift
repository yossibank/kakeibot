import SwiftUI

public struct ProStore: Sendable {
    public let status: Status
    public let updates: Updates
    public let price: Price
    public let purchase: Purchase
    public let restore: Restore

    public init(
        status: @escaping Status,
        updates: @escaping Updates,
        price: @escaping Price,
        purchase: @escaping Purchase,
        restore: @escaping Restore
    ) {
        self.status = status
        self.updates = updates
        self.price = price
        self.purchase = purchase
        self.restore = restore
    }
}

public extension ProStore {
    typealias Status = @Sendable () async -> ProStatus
    typealias Updates = @Sendable () -> AsyncStream<ProStatus>
    typealias Price = @Sendable () async throws -> String
    typealias Purchase = @Sendable () async throws -> ProStatus
    typealias Restore = @Sendable () async throws -> ProStatus

    static let unavailable = Self(
        status: {
            .locked
        },
        updates: {
            AsyncStream { continuation in
                continuation.finish()
            }
        },
        price: {
            throw ProStoreError.unavailable
        },
        purchase: {
            .locked
        },
        restore: {
            .locked
        }
    )
}

public enum ProStoreError: Error {
    case unavailable
    case cancelled
}

public extension EnvironmentValues {
    @Entry var proStore: ProStore = .unavailable
    @Entry var isPro = false
}
