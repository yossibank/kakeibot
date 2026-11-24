import Observation

@MainActor
@Observable
public final class SettingsBoardSnapshotInput<Snapshot>: SettingsBoardInput {
    public internal(set) var snapshot: Snapshot?

    public init() {}
}
