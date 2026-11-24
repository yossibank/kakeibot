import Store

public enum SetupItem: String, CaseIterable, Hashable, Identifiable, Sendable {
    case budget
    case monthStart
    case wallets
    case categories
    case recurrings
    case templates
    case reminder
    case launchScreen
    case theme
    case appIcon
    case themeStyle
    case themeLook
    case homeSections

    public static let onboarding: [Self] = [
        .wallets,
        .categories,
        .recurrings,
        .templates,
        .reminder
    ]

    public static let customize: [Self] = [
        .launchScreen,
        .theme,
        .appIcon,
        .themeStyle,
        .themeLook
    ]

    public static let home: [Self] = [
        .budget,
        .wallets,
        .recurrings
    ]

    public var id: Self {
        self
    }

    public var title: String {
        switch self {
        case .budget: "月の予算"
        case .monthStart: "月の始まり"
        case .wallets: "口座と今の残高"
        case .categories: "使うカテゴリ"
        case .recurrings: "固定費"
        case .templates: "テンプレート"
        case .reminder: "記録忘れの通知"
        case .launchScreen: "起動時に開く画面"
        case .theme: "テーマ"
        case .appIcon: "アプリアイコン"
        case .themeStyle: "文字"
        case .themeLook: "形と動き"
        case .homeSections: "ホームに出すもの"
        }
    }

    public var systemImage: String {
        switch self {
        case .budget: "chart.bar"
        case .monthStart: "calendar"
        case .wallets: "building.columns"
        case .categories: "tag"
        case .recurrings: "repeat"
        case .templates: "rectangle.stack"
        case .reminder: "bell"
        case .launchScreen: "iphone"
        case .theme: "paintpalette"
        case .appIcon: "app.badge"
        case .themeStyle: "textformat"
        case .themeLook: "square.on.circle"
        case .homeSections: "rectangle.grid.1x2"
        }
    }

    public func isDone(in progress: SetupProgress) -> Bool {
        switch self {
        case .budget: progress.hasBudget
        case .wallets: progress.hasWalletBalance
        case .recurrings: progress.hasRecurring
        case .reminder: progress.hasReminder
        case .theme: progress.hasTheme
        case .monthStart, .categories, .templates, .launchScreen, .appIcon, .themeStyle, .themeLook,
             .homeSections: false
        }
    }
}
