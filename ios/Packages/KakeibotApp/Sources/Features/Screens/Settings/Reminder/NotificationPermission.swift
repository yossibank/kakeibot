import Core
import SwiftUI

public struct NotificationPermission: Sendable {
    public let authorization: Check
    public let request: Request

    public init(
        authorization: @escaping Check,
        request: @escaping Request
    ) {
        self.authorization = authorization
        self.request = request
    }
}

public extension NotificationPermission {
    typealias Check = @Sendable () async -> NotificationAuthorization
    typealias Request = @Sendable () async -> Bool

    static let allowed = Self {
        .allowed
    } request: {
        true
    }
}

public extension EnvironmentValues {
    @Entry var notificationPermission: NotificationPermission = .allowed
}
