import Core
import SwiftUI

public struct NotificationPermission: Sendable {
    public let authorization: @Sendable () async -> NotificationAuthorization
    public let request: @Sendable () async -> Bool

    public init(
        authorization: @escaping @Sendable () async
            -> NotificationAuthorization,
        request: @escaping @Sendable () async -> Bool
    ) {
        self.authorization = authorization
        self.request = request
    }
}

public extension NotificationPermission {
    static let allowed = Self {
        .allowed
    } request: {
        true
    }
}

public extension EnvironmentValues {
    @Entry var notificationPermission: NotificationPermission = .allowed
}
