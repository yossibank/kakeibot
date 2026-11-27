public struct SettingsBoardShown<
    ID: Hashable & Sendable,
    Destination: Hashable & Sendable
>: ScreenEditable {
    public var destination: Destination?
    public var openId: ID?

    public internal(set) var prompt: SettingsBoardPrompt<ID>?

    public init() {}
}
