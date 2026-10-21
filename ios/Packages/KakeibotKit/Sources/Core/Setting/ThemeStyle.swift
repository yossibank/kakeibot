public struct ThemeStyle: Hashable, Sendable {
    public var corner: ThemeCorner
    public var displayFont: ThemeFont
    public var textFont: ThemeFont
    public var textSize: ThemeTextSize

    public init(
        corner: ThemeCorner,
        displayFont: ThemeFont,
        textFont: ThemeFont,
        textSize: ThemeTextSize = .standard
    ) {
        self.corner = corner
        self.displayFont = displayFont
        self.textFont = textFont
        self.textSize = textSize
    }
}

public extension ThemeStyle {
    static let standard = ThemeStyle(
        corner: .standard,
        displayFont: .mincho,
        textFont: .gothic
    )
}
