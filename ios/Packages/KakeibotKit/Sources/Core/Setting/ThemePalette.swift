public struct ThemePalette: Hashable, Sendable {
    public var backgroundTop: UInt32
    public var backgroundBottom: UInt32
    public var panel: UInt32
    public var cardTop: UInt32
    public var cardBottom: UInt32
    public var line: UInt32
    public var accent: UInt32
    public var accentDeep: UInt32
    public var accentLight: UInt32
    public var text: UInt32
    public var subtext: UInt32
    public var hint: UInt32

    public init(
        backgroundTop: UInt32,
        backgroundBottom: UInt32,
        panel: UInt32,
        cardTop: UInt32,
        cardBottom: UInt32,
        line: UInt32,
        accent: UInt32,
        accentDeep: UInt32,
        accentLight: UInt32,
        text: UInt32,
        subtext: UInt32,
        hint: UInt32
    ) {
        self.backgroundTop = backgroundTop
        self.backgroundBottom = backgroundBottom
        self.panel = panel
        self.cardTop = cardTop
        self.cardBottom = cardBottom
        self.line = line
        self.accent = accent
        self.accentDeep = accentDeep
        self.accentLight = accentLight
        self.text = text
        self.subtext = subtext
        self.hint = hint
    }
}

public extension ThemePalette {
    enum Role: String, CaseIterable, Codable, Sendable {
        case backgroundTop
        case backgroundBottom
        case panel
        case cardTop
        case cardBottom
        case line
        case accent
        case accentDeep
        case accentLight
        case text
        case subtext
        case hint
    }

    static let night = ThemePalette(
        backgroundTop: 0x16223D,
        backgroundBottom: 0x080C16,
        panel: 0x0E1628,
        cardTop: 0x141C2F,
        cardBottom: 0x090D18,
        line: 0x26314A,
        accent: 0xCDAA6B,
        accentDeep: 0x8F6C38,
        accentLight: 0xF4E6C1,
        text: 0xEDE6D6,
        subtext: 0x8C97AE,
        hint: 0x7E89A0
    )

    subscript(role: Role) -> UInt32 {
        switch role {
        case .backgroundTop: backgroundTop
        case .backgroundBottom: backgroundBottom
        case .panel: panel
        case .cardTop: cardTop
        case .cardBottom: cardBottom
        case .line: line
        case .accent: accent
        case .accentDeep: accentDeep
        case .accentLight: accentLight
        case .text: text
        case .subtext: subtext
        case .hint: hint
        }
    }
}
