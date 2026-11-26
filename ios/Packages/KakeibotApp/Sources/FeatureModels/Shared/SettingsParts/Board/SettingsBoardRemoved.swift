import Core
import Observation

@MainActor
@Observable
public final class SettingsBoardRemoved<ID: Sendable> {
    public internal(set) var bulkDelete: SettingsBulkDelete?

    public let hidden: UndoNotice<ID>
    public let deletion: UndoNotice<Deletion>

    public init(wait: ScreenWait) {
        self.hidden = UndoNotice(wait: wait)
        self.deletion = UndoNotice(wait: wait)
    }
}

public extension SettingsBoardRemoved {
    var bulkNote: String? {
        bulkDelete?.note(for: deletion.current)
    }
}
