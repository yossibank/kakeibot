import UIKit

public struct AppIconSwitcher: Sendable {
    let currentName: @MainActor @Sendable () -> String?
    let setName: @MainActor @Sendable (String?) async throws -> Void

    public init(
        currentName: @escaping @MainActor @Sendable () -> String?,
        setName: @escaping @MainActor @Sendable (String?) async throws -> Void
    ) {
        self.currentName = currentName
        self.setName = setName
    }
}

public extension AppIconSwitcher {
    static let live = AppIconSwitcher(
        currentName: {
            UIApplication.shared.alternateIconName
        },
        setName: { name in
            try await Task.sleep(for: .seconds(0.5))
            try await UIApplication.shared.setAlternateIconName(name)
        }
    )
}
