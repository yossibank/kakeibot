import Store

public enum SetupItem: String, CaseIterable, Hashable, Identifiable, Sendable {
    case budget
    case wallets
    case categories
    case recurrings
    case templates
    case reminder
    case theme

    public static let onboarding: [Self] = [
        .wallets,
        .categories,
        .recurrings,
        .templates,
        .reminder,
        .theme
    ]

    public static let home: [Self] = [.budget, .wallets, .recurrings]

    public var id: Self {
        self
    }

    public var title: String {
        switch self {
        case .budget: "月の予算"
        case .wallets: "口座と今の残高"
        case .categories: "使うカテゴリ"
        case .recurrings: "固定費（家賃・通信など）"
        case .templates: "テンプレート"
        case .reminder: "記録忘れの通知"
        case .theme: "テーマ"
        }
    }

    public var systemImage: String {
        switch self {
        case .budget: "chart.bar"
        case .wallets: "building.columns"
        case .categories: "tag"
        case .recurrings: "repeat"
        case .templates: "rectangle.stack"
        case .reminder: "bell"
        case .theme: "paintpalette"
        }
    }

    public func isDone(in progress: SetupProgress) -> Bool {
        switch self {
        case .budget: progress.hasBudget
        case .wallets: progress.hasWalletBalance
        case .recurrings: progress.hasRecurring
        case .reminder: progress.hasReminder
        case .theme: progress.hasTheme
        case .categories, .templates: false
        }
    }
}
