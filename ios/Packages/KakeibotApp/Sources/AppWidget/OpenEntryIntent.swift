import AppIntents
import Core
import Foundation
import Notifications

struct OpenEntryIntent: AppIntent {
    static let openAppWhenRun = true

    static var title: LocalizedStringResource {
        "入力シートを開く"
    }

    static var isDiscoverable: Bool {
        false
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let today = LocalDate(Date(), in: .current)

        NotificationRouter.shared.open(.entry(today))

        return .result()
    }
}
