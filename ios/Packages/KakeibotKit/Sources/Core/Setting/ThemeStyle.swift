public struct ThemeStyle: Hashable, Sendable {
    public var corner: ThemeCorner
    public var displayFont: ThemeFont
    public var textFont: ThemeFont
    public var textSize: ThemeTextSize
    public var rowSpacing: ThemeRowSpacing
    public var stampShape: ThemeStampShape
    public var showsTabTitles: Bool
    public var backdrop: ThemeBackdrop
    public var haptics: Bool
    public var decorations: Bool

    public init(
        corner: ThemeCorner,
        displayFont: ThemeFont,
        textFont: ThemeFont,
        textSize: ThemeTextSize = .standard,
        rowSpacing: ThemeRowSpacing = .standard,
        stampShape: ThemeStampShape = .circle,
        showsTabTitles: Bool = true,
        backdrop: ThemeBackdrop = .plain,
        haptics: Bool = true,
        decorations: Bool = true
    ) {
        self.corner = corner
        self.displayFont = displayFont
        self.textFont = textFont
        self.textSize = textSize
        self.rowSpacing = rowSpacing
        self.stampShape = stampShape
        self.showsTabTitles = showsTabTitles
        self.backdrop = backdrop
        self.haptics = haptics
        self.decorations = decorations
    }
}

public extension ThemeStyle {
    static let standard = ThemeStyle(corner: .standard, displayFont: .mincho, textFont: .gothic)
}
