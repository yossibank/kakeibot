public struct ThemeStyle: Hashable, Sendable {
    public var corner: ThemeCorner
    public var displayFont: ThemeFont
    public var textFont: ThemeFont

    public init(
        corner: ThemeCorner,
        displayFont: ThemeFont,
        textFont: ThemeFont
    ) {
        self.corner = corner
        self.displayFont = displayFont
        self.textFont = textFont
    }
}

public extension ThemeStyle {
    static let standard = ThemeStyle(
        corner: .standard,
        displayFont: .mincho,
        textFont: .gothic
    )
}
