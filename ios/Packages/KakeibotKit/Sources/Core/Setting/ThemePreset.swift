public enum ThemePreset: String, CaseIterable, Codable, Sendable {
    case navy
    case forest
    case wine
    case plum
    case charcoal
}

public extension ThemePreset {
    var title: String {
        switch self {
        case .navy: "ネイビー"
        case .forest: "フォレスト"
        case .wine: "ワイン"
        case .plum: "プラム"
        case .charcoal: "チャコール"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .navy:
            .night
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
                accentLight: 0xF4E6C1,
                text: 0xEDE6D6,
                subtext: 0x8FB0A3,
                hint: 0x7E9C90
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
                accentLight: 0xF4E6C1,
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
                accentLight: 0xF4E6C1,
                text: 0xEDE6D6,
                subtext: 0xA99AB5,
                hint: 0x958AA3
            )
        case .charcoal:
            ThemePalette(
                backgroundTop: 0x1D1D20,
                backgroundBottom: 0x050506,
                panel: 0x111114,
                cardTop: 0x18181B,
                cardBottom: 0x08080A,
                line: 0x2C2C31,
                accent: 0xC9CCD2,
                accentDeep: 0x7D8188,
                accentLight: 0xF2F2F0,
                text: 0xECECEA,
                subtext: 0x9A9CA3,
                hint: 0x878A92
            )
        }
    }
}
