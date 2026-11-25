import Core

public struct SettingsEditOutcome<Saved: Sendable>: Sendable {
    public let saved: Saved?
    public let isHidden: Bool?
    public let deletion: Deletion?
    public let closes: Bool

    init(
        saved: Saved? = nil,
        isHidden: Bool? = nil,
        deletion: Deletion? = nil,
        closes: Bool = true
    ) {
        self.saved = saved
        self.isHidden = isHidden
        self.deletion = deletion
        self.closes = closes
    }
}
