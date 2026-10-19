import Core
import Observation
import Store

@MainActor
@Observable
public final class SettingsHintModel {
    public private(set) var isClosed = true

    private let database: AppDatabase
    private let hint: ScreenHint

    public init(
        database: AppDatabase,
        hint: ScreenHint
    ) {
        self.database = database
        self.hint = hint
    }
}

public extension SettingsHintModel {
    func load() async {
        let closed = try? await database.setting(.closedHints)
        isClosed = closed?.contains(hint) ?? false
    }

    func close() async {
        isClosed = true

        let closed = await (try? database.setting(.closedHints)) ?? []
        try? await database.setSetting(.closedHints, to: closed.union([hint]))
    }
}
