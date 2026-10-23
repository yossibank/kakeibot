import AppIntents
import Core
import Foundation
import Store

struct UndoWidgetEntryIntent: AppIntent {
    @Parameter(title: "記録")
    var entryId: String

    init() {}

    init(_ id: Entry.ID) {
        self.entryId = id.description
    }
}

extension UndoWidgetEntryIntent {
    static var title: LocalizedStringResource {
        "ウィジェットの記録を取り消す"
    }

    static var isDiscoverable: Bool {
        false
    }

    func perform() async throws -> some IntentResult {
        let today = LocalDate(Date(), in: .current)

        guard let id = Entry.ID(entryId) else {
            return .result()
        }

        let database = try AppDatabase.appGroupForWriting()

        try await database.undoWidgetEntry(id)
        await database.finishWidgetWrite(today: today)

        return .result()
    }
}
