import Core
import Observation

@MainActor
@Observable
public final class SettingsBoardSnapshotInput<Snapshot>: SettingsBoardInput {
    public internal(set) var snapshot: Snapshot?

    public let hint: SettingsFoldInput
    public let hiddenList: SettingsFoldInput

    init(screen: SettingsScreen) {
        self.hint = .hint(screen)
        self.hiddenList = .hiddenList(screen)
    }
}
