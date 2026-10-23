import AppIntents
import Core
import Foundation

struct OpenEntryIntent: AppIntent {
    static var title: LocalizedStringResource {
        "入力シートを開く"
    }

    static var isDiscoverable: Bool {
        false
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        let today = LocalDate(Date(), in: .current)

        guard let url = PlannedNotification.Route.entry(today).url else {
            throw URLError(.badURL)
        }

        return .result(opensIntent: OpenURLIntent(url))
    }
}
