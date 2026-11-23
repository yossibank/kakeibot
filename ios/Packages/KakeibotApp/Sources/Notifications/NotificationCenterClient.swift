import Core
import Foundation
import UserNotifications

public protocol NotificationCenterClient: Sendable {
    func pendingIdentifiers() async -> [String]

    func add(
        identifier: String,
        title: String,
        body: String,
        link: String,
        at components: DateComponents
    ) async throws

    func remove(_ identifiers: [String]) async
    func authorization() async -> NotificationAuthorization
    func requestAuthorization() async -> Bool
}
