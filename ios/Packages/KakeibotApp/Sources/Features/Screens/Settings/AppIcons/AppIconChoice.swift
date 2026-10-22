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
}

public extension AppIconChoice {
    struct Look: Sendable {
        let background: [String]
        let yen: [String]
        let dial: [String]
    }

    init(_ preset: ThemePreset) {
        self =
            switch preset {
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

    init?(_ choice: ThemeChoice) {
        switch choice {
        case .system: self = .white
        case let .preset(preset): self.init(preset)
        case .custom: return nil
        }
    }

    init(alternateName: String?) {
        let choice = Self.allCases.first { $0.alternateName == alternateName }
        self = choice ?? .white
    }

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
        switch self {
        case .navy:
            Look(
                background: ["#18253F", "#060B16"],
                yen: Self.goldMark,
                dial: Self.goldMark
            )
        case .black:
            Look(
                background: ["#1D1D20", "#050506"],
                yen: Self.goldMark,
                dial: Self.goldMark
            )
        case .forest:
            Look(
                background: ["#143C32", "#04130E"],
                yen: Self.goldMark,
                dial: Self.goldMark
            )
        case .teal:
            Look(
                background: ["#0F3B44", "#04161A"],
                yen: Self.silverMark,
                dial: Self.silverMark
            )
        case .wine:
            Look(
                background: ["#4A1626", "#16050A"],
                yen: Self.goldMark,
                dial: Self.goldMark
            )
        case .plum:
            Look(
                background: ["#36203F", "#0F0714"],
                yen: Self.goldMark,
                dial: Self.goldMark
            )
        case .ivory:
            Look(
                background: ["#F8F4EB", "#E3DAC7"],
                yen: Self.deepGoldMark,
                dial: Self.inkMark
            )
        case .white:
            Look(
                background: ["#FFFFFF", "#E6E6EA"],
                yen: Self.deepGoldMark,
                dial: Self.deepGoldMark
            )
        case .sky:
            Look(
                background: ["#E6EFF8", "#A9C2DB"],
                yen: ["#18253F", "#0B1324"],
                dial: ["#18253F", "#0B1324"]
            )
        case .sage:
            Look(
                background: ["#DFE7D8", "#A3B49A"],
                yen: ["#143C32", "#0A241D"],
                dial: ["#143C32", "#0A241D"]
            )
        case .rose:
            Look(
                background: ["#F6E0D8", "#CC9A8E"],
                yen: ["#5A1E2E", "#3A0F1C"],
                dial: ["#5A1E2E", "#3A0F1C"]
            )
        case .gold:
            Look(
                background: ["#F1DFB2", "#9A773F"],
                yen: Self.inkMark,
                dial: Self.inkMark
            )
        }
    }
}

private extension AppIconChoice {
    static let goldMark = ["#F4E6C1", "#8F6C38"]
    static let deepGoldMark = ["#A87A35", "#5E4116"]
    static let silverMark = ["#F7F7F5", "#9EA1A6"]
    static let inkMark = ["#1A1A1C", "#1A1A1C"]
}
