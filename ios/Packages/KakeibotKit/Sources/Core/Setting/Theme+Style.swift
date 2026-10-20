public extension Theme {
    var style: ThemeStyle {
        let standard = ThemeStyle.standard

        return ThemeStyle(
            corner: ThemeCorner(rawValue: cornerRadius) ?? standard.corner,
            font: ThemeFont(rawValue: fontId) ?? standard.font
        )
    }
}
