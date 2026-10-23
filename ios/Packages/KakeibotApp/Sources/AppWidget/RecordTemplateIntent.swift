import AppIntents
import Core
import Foundation
import Store

struct RecordTemplateIntent: AppIntent {
    @Parameter(title: "テンプレート")
    var templateId: String

    init() {}

    init(_ id: EntryTemplate.ID) {
        self.templateId = id.description
    }
}

extension RecordTemplateIntent {
    static var title: LocalizedStringResource {
        "テンプレートで記録する"
    }

    static var isDiscoverable: Bool {
        false
    }

    func perform() async throws -> some IntentResult {
        let now = Date()
        let today = LocalDate(now, in: .current)

        guard let id = EntryTemplate.ID(templateId) else {
            return .result()
        }

        let database = try AppDatabase.appGroupForWriting()

        try await database.recordFromWidget(id, on: today, at: now)
        await database.finishWidgetWrite(today: today)

        return .result()
    }
}
