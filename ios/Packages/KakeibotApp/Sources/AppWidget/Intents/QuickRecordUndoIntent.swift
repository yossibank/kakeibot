import AppIntents
import Core
import Foundation
import Store

struct QuickRecordUndoIntent: AppIntent {
    @Parameter(title: "記録")
    var entryId: String

    init() {}

    init(_ id: Entry.ID) {
        self.entryId = id.description
    }
}

extension QuickRecordUndoIntent {
    static var title: LocalizedStringResource {
        "ウィジェットの記録を取り消す"
    }

    static var isDiscoverable: Bool {
        false
    }

    func perform() async throws -> some IntentResult {
        let now = Date()
        let today = LocalDate(now, in: .current)

        guard let id = Entry.ID(entryId) else {
            return .result()
        }

        let database = try AppDatabase.appGroupForWriting()

        try await database.undoWidgetEntry(id, at: now)

        await database.finishWidgetWrite(today: today)

        return .result()
    }
}
