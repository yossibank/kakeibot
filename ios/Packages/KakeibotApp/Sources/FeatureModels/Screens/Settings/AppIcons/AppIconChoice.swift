import Core

public enum AppIconChoice: CaseIterable, Sendable {
    case white
    case ivory
    case sky
    case sage
    case rose
    case gold
    case black
    case navy
    case forest
    case teal
    case wine
    case plum

    public init(_ preset: ThemePreset) {
        self = switch preset {
        case .navy: .navy
        case .black: .black
        case .forest: .forest
        case .teal: .teal
        case .wine: .wine
        case .plum: .plum
        case .ivory: .ivory
        case .white: .white
        case .sky: .sky
        case .sage: .sage
        case .rose: .rose
        case .gold: .gold
        }
    }

    public init?(_ choice: ThemeChoice) {
        switch choice {
        case .system: self = .white
        case let .preset(preset): self.init(preset)
        case .custom: return nil
        }
    }

    public init(alternateName: String?) {
        let choice = Self.allCases.first { $0.alternateName == alternateName }

        self = choice ?? .white
    }
}

public extension AppIconChoice {
    struct Look: Sendable {
        public let background: [String]
        public let yen: [String]
        public let dial: [String]
    }
}

public extension AppIconChoice {
    var title: String {
        switch self {
        case .navy: "ネイビー"
        case .black: "ブラック"
        case .forest: "フォレスト"
        case .teal: "ティール"
        case .wine: "ワイン"
        case .plum: "プラム"
        case .ivory: "アイボリー"
        case .white: "ホワイト"
        case .sky: "スカイ"
        case .sage: "セージ"
        case .rose: "ローズ"
        case .gold: "ゴールド"
        }
    }

    var isLight: Bool {
        switch self {
        case .ivory, .white, .sky, .sage, .rose, .gold: true
        default: false
        }
    }

    var alternateName: String? {
        switch self {
        case .white: nil
        case .navy: "AppIcon-Navy"
        case .black: "AppIcon-Black"
        case .forest: "AppIcon-Forest"
        case .teal: "AppIcon-Teal"
        case .wine: "AppIcon-Wine"
        case .plum: "AppIcon-Plum"
        case .ivory: "AppIcon-Ivory"
        case .sky: "AppIcon-Sky"
        case .sage: "AppIcon-Sage"
        case .rose: "AppIcon-Rose"
        case .gold: "AppIcon-Gold"
        }
    }

    var look: Look {
        Look(background: backgroundColors, yen: yenColors, dial: dialColors)
    }
}

private extension AppIconChoice {
    static let goldMark = ["#F4E6C1", "#8F6C38"]
    static let deepGoldMark = ["#A87A35", "#5E4116"]
    static let silverMark = ["#F7F7F5", "#9EA1A6"]
    static let inkMark = ["#1A1A1C", "#1A1A1C"]

    var backgroundColors: [String] {
        switch self {
        case .navy: ["#18253F", "#060B16"]
        case .black: ["#1D1D20", "#050506"]
        case .forest: ["#143C32", "#04130E"]
        case .teal: ["#0F3B44", "#04161A"]
        case .wine: ["#4A1626", "#16050A"]
        case .plum: ["#36203F", "#0F0714"]
        case .ivory: ["#F8F4EB", "#E3DAC7"]
        case .white: ["#FFFFFF", "#E6E6EA"]
        case .sky: ["#E6EFF8", "#A9C2DB"]
        case .sage: ["#DFE7D8", "#A3B49A"]
        case .rose: ["#F6E0D8", "#CC9A8E"]
        case .gold: ["#F1DFB2", "#9A773F"]
        }
    }

    var yenColors: [String] {
        switch self {
        case .navy, .black, .forest, .wine, .plum: Self.goldMark
        case .teal: Self.silverMark
        case .ivory, .white: Self.deepGoldMark
        case .sky: ["#18253F", "#0B1324"]
        case .sage: ["#143C32", "#0A241D"]
        case .rose: ["#5A1E2E", "#3A0F1C"]
        case .gold: Self.inkMark
        }
    }

    var dialColors: [String] {
        self == .ivory ? Self.inkMark : yenColors
    }
}
