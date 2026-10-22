import Core

public struct RewardRuleList: Equatable, Sendable {
    public let rules: [RewardRule]
    public let icons: [Icon.ID: Icon]

    public init(
        rules: [RewardRule],
        icons: [Icon.ID: Icon]
    ) {
        self.rules = rules
        self.icons = icons
    }
}
