import Core
import SwiftUI

public struct NotificationPermission: Sendable {
    public let authorization: Check
    public let request: Request
    public let reschedule: Reschedule

    public init(
        authorization: @escaping Check,
        request: @escaping Request,
        reschedule: @escaping Reschedule = {}
    ) {
        self.authorization = authorization
        self.request = request
        self.reschedule = reschedule
    }
}

public extension NotificationPermission {
    typealias Check = @Sendable () async -> NotificationAuthorization
    typealias Request = @Sendable () async -> Bool
    typealias Reschedule = @Sendable () async -> Void

    static let allowed = Self {
        .allowed
    } request: {
        true
    }

    func requestIfUndecided() async {
        guard await authorization() == .notDetermined else {
            return
        }

        if await request() {
            await reschedule()
        }
    }
}

public extension EnvironmentValues {
    @Entry var notificationPermission: NotificationPermission = .allowed
}
