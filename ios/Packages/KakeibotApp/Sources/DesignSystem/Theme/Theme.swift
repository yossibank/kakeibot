public struct Theme: Hashable, Sendable {
    let backgroundTop: UInt32
    let backgroundBottom: UInt32
    let panel: UInt32
    let cardTop: UInt32
    let cardBottom: UInt32
    let line: UInt32
    let accent: UInt32
    let accentDeep: UInt32
    let accentLight: UInt32
    let text: UInt32
    let subtext: UInt32
    let hint: UInt32
}

public extension Theme {
    static let night = Theme(
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
}
