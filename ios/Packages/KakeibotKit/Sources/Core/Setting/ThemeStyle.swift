public struct ThemeStyle: Hashable, Sendable {
    public var corner: ThemeCorner
    public var font: ThemeFont

    public init(
        corner: ThemeCorner,
        font: ThemeFont
    ) {
        self.corner = corner
        self.font = font
    }
}

public extension ThemeStyle {
    static let standard = ThemeStyle(corner: .standard, font: .mincho)
}
