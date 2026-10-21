import Core

extension ThemeChoice {
    func title(in themes: [Theme]) -> String {
        switch self {
        case let .preset(preset):
            return preset.title
        case let .custom(id):
            let theme = themes.first { $0.id == id }
            return theme?.name ?? ThemePreset.navy.title
        }
    }
}
