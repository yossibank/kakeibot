import Store

public enum SetupItem: String, CaseIterable, Hashable, Identifiable, Sendable {
    case budget
    case wallets
    case categories
    case recurrings
    case templates
    case reminder
    case launchScreen
    case startsWithAmount
    case theme
    case appIcon
    case themeStyle

    public static let onboarding: [Self] = [
        .wallets,
        .categories,
        .recurrings,
        .templates,
        .reminder
    ]

    public static let customize: [Self] = [
        .launchScreen,
        .startsWithAmount,
        .theme,
        .appIcon,
        .themeStyle
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
        case .launchScreen: "起動時に開く画面"
        case .startsWithAmount: "金額から入力"
        case .theme: "テーマ"
        case .appIcon: "アプリアイコン"
        case .themeStyle: "文字と角の丸み"
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
        case .launchScreen: "iphone"
        case .startsWithAmount: "yensign"
        case .theme: "paintpalette"
        case .appIcon: "app.badge"
        case .themeStyle: "textformat"
        }
    }

    public var isToggle: Bool {
        self == .startsWithAmount
    }

    public func isDone(in progress: SetupProgress) -> Bool {
        switch self {
        case .budget: progress.hasBudget
        case .wallets: progress.hasWalletBalance
        case .recurrings: progress.hasRecurring
        case .reminder: progress.hasReminder
        case .theme: progress.hasTheme
        case .categories, .templates, .launchScreen, .startsWithAmount, .appIcon, .themeStyle: false
        }
    }
}
