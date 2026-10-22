import Core

extension ThemeChoice {
    static let systemTitle = "iPhone に合わせる"

    func title(in themes: [Theme]) -> String {
        switch self {
        case .system:
            return Self.systemTitle
        case let .preset(preset):
            return preset.title
        case let .custom(id):
            let theme = themes.first { $0.id == id }
            return theme?.name ?? Self.systemTitle
        }
    }
}
