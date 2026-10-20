public enum ThemePreset: String, CaseIterable, Codable, Sendable {
    case navy
    case black
    case forest
    case teal
    case wine
    case plum
    case ivory
    case white
    case sky
    case sage
    case rose
    case gold
}

public extension ThemePreset {
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

    var palette: ThemePalette {
        switch self {
        case .navy:
            .night
        case .black:
            ThemePalette(
                backgroundTop: 0x1D1D20,
                backgroundBottom: 0x050506,
                panel: 0x111114,
                cardTop: 0x18181B,
                cardBottom: 0x08080A,
                line: 0x2C2C31,
                accent: 0xCDAA6B,
                accentDeep: 0x8F6C38,
                accentStrong: 0xF4E6C1,
                text: 0xEDE6D6,
                subtext: 0x9A9CA3,
                hint: 0x878A92
            )
        case .forest:
            ThemePalette(
                backgroundTop: 0x143C32,
                backgroundBottom: 0x04130E,
                panel: 0x0B241D,
                cardTop: 0x12322A,
                cardBottom: 0x06150F,
                line: 0x24493E,
                accent: 0xCDAA6B,
                accentDeep: 0x8F6C38,
                accentStrong: 0xF4E6C1,
                text: 0xEDE6D6,
                subtext: 0x8FB0A3,
                hint: 0x7E9C90
            )
        case .teal:
            ThemePalette(
                backgroundTop: 0x0F3B44,
                backgroundBottom: 0x04161A,
                panel: 0x0A262C,
                cardTop: 0x0E333B,
                cardBottom: 0x05181C,
                line: 0x1E4A53,
                accent: 0xC9CCD2,
                accentDeep: 0x7D8188,
                accentStrong: 0xF2F2F0,
                text: 0xECEFEE,
                subtext: 0x8FAEB3,
                hint: 0x7C9CA1
            )
        case .wine:
            ThemePalette(
                backgroundTop: 0x3A1220,
                backgroundBottom: 0x12050A,
                panel: 0x220A13,
                cardTop: 0x2E0F1A,
                cardBottom: 0x14060B,
                line: 0x4A2230,
                accent: 0xCDAA6B,
                accentDeep: 0x8F6C38,
                accentStrong: 0xF4E6C1,
                text: 0xEDE6D6,
                subtext: 0xB39AA2,
                hint: 0xA0858E
            )
        case .plum:
            ThemePalette(
                backgroundTop: 0x2C1A36,
                backgroundBottom: 0x0D0712,
                panel: 0x1B1022,
                cardTop: 0x26162E,
                cardBottom: 0x0F0915,
                line: 0x3E2A4A,
                accent: 0xCDAA6B,
                accentDeep: 0x8F6C38,
                accentStrong: 0xF4E6C1,
                text: 0xEDE6D6,
                subtext: 0xA99AB5,
                hint: 0x958AA3
            )
        case .ivory:
            ThemePalette(
                backgroundTop: 0xF8F4EB,
                backgroundBottom: 0xF2ECE0,
                panel: 0xF1EBDF,
                cardTop: 0xFFFFFF,
                cardBottom: 0xFBF9F4,
                line: 0xDCD2BF,
                accent: 0x8A6420,
                accentDeep: 0xB89657,
                accentStrong: 0x4A340C,
                text: 0x2A2418,
                subtext: 0x6B6152,
                hint: 0x7A705F
            )
        case .white:
            ThemePalette(
                backgroundTop: 0xFFFFFF,
                backgroundBottom: 0xF8F8FA,
                panel: 0xF5F5F8,
                cardTop: 0xFFFFFF,
                cardBottom: 0xFBFBFD,
                line: 0xDEDEE4,
                accent: 0x8A6420,
                accentDeep: 0xB89657,
                accentStrong: 0x4A340C,
                text: 0x1E1E22,
                subtext: 0x63636B,
                hint: 0x74747C
            )
        case .sky:
            ThemePalette(
                backgroundTop: 0xEEF4FA,
                backgroundBottom: 0xE7EEF6,
                panel: 0xE5EDF6,
                cardTop: 0xFFFFFF,
                cardBottom: 0xF9FBFD,
                line: 0xC9D6E5,
                accent: 0x2F5A8C,
                accentDeep: 0x8AA8CC,
                accentStrong: 0x14315A,
                text: 0x17233A,
                subtext: 0x54627A,
                hint: 0x637089
            )
        case .sage:
            ThemePalette(
                backgroundTop: 0xEEF3EA,
                backgroundBottom: 0xE7EEE2,
                panel: 0xE6EDE1,
                cardTop: 0xFFFFFF,
                cardBottom: 0xFAFBF9,
                line: 0xCAD8C2,
                accent: 0x2F6A55,
                accentDeep: 0x8FB3A2,
                accentStrong: 0x143C32,
                text: 0x1A2A22,
                subtext: 0x56685E,
                hint: 0x65776C
            )
        case .rose:
            ThemePalette(
                backgroundTop: 0xF8EEEC,
                backgroundBottom: 0xF4E7E4,
                panel: 0xF3E5E2,
                cardTop: 0xFFFFFF,
                cardBottom: 0xFCF8F7,
                line: 0xE3CDC8,
                accent: 0x9C3D52,
                accentDeep: 0xC98A97,
                accentStrong: 0x5A1A2A,
                text: 0x2E1C1E,
                subtext: 0x6E5559,
                hint: 0x7C6266
            )
        case .gold:
            ThemePalette(
                backgroundTop: 0xF4E8C8,
                backgroundBottom: 0xEDDDB3,
                panel: 0xEEDFB6,
                cardTop: 0xFFF8E6,
                cardBottom: 0xFAF1D8,
                line: 0xD8C189,
                accent: 0x6E4E1C,
                accentDeep: 0xA88545,
                accentStrong: 0x3A2808,
                text: 0x1A1A1C,
                subtext: 0x5E5240,
                hint: 0x6A5D47
            )
        }
    }
}
