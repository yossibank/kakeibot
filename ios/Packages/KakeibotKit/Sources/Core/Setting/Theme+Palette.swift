public extension Theme {
    var palette: ThemePalette {
        ThemeDraft(self).palette ?? .night
    }
}
