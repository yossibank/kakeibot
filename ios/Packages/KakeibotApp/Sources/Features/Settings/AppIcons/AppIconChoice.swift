public enum AppIconChoice: CaseIterable, Sendable {
    case navy
    case black
    case forest
    case silver
    case ivory
    case white
    case gold
}

public extension AppIconChoice {
    struct Look: Sendable {
        let background: [String]
        let yen: [String]
        let dial: [String]
    }

    init(alternateName: String?) {
        let choice = Self.allCases.first { $0.alternateName == alternateName }
        self = choice ?? .navy
    }

    var title: String {
        switch self {
        case .navy: "紺"
        case .black: "黒"
        case .forest: "森"
        case .silver: "銀"
        case .ivory: "象牙"
        case .white: "白"
        case .gold: "金"
        }
    }

    var alternateName: String? {
        switch self {
        case .navy: nil
        case .black: "AppIcon-Black"
        case .forest: "AppIcon-Forest"
        case .silver: "AppIcon-Silver"
        case .ivory: "AppIcon-Ivory"
        case .white: "AppIcon-White"
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
        case .silver:
            Look(
                background: ["#1D1D20", "#050506"],
                yen: ["#F7F7F5", "#9EA1A6"],
                dial: ["#F7F7F5", "#9EA1A6"]
            )
        case .ivory:
            Look(
                background: ["#F8F4EB", "#E3DAC7"],
                yen: Self.goldMark,
                dial: Self.inkMark
            )
        case .white:
            Look(
                background: ["#FFFFFF", "#E6E6EA"],
                yen: Self.goldMark,
                dial: Self.goldMark
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
    static let inkMark = ["#1A1A1C", "#1A1A1C"]
}
