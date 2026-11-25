import Core

public struct SettingsBoardRemoved<ID: Sendable>: Sendable {
    public var hiddenId: ID?
    public var deletion: Deletion?
    public var bulkDelete: SettingsBulkDelete?

    public init() {}
}
