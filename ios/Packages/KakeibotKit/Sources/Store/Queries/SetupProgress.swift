public struct SetupProgress: Equatable, Sendable {
    public let hasBudget: Bool
    public let hasWalletBalance: Bool
    public let hasRecurring: Bool
    public let hasReminder: Bool
    public let hasTheme: Bool

    public init(
        hasBudget: Bool,
        hasWalletBalance: Bool,
        hasRecurring: Bool,
        hasReminder: Bool,
        hasTheme: Bool
    ) {
        self.hasBudget = hasBudget
        self.hasWalletBalance = hasWalletBalance
        self.hasRecurring = hasRecurring
        self.hasReminder = hasReminder
        self.hasTheme = hasTheme
    }
}
