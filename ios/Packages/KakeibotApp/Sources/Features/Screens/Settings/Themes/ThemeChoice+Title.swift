import Core

extension ThemeChoice {
    static let systemTitle = "iPhone に合わせる"

    func title(in themes: [Theme]) -> String {
        switch self {
        case .system: Self.systemTitle
        case let .preset(preset): preset.title
        case let .custom(id): themes.first { $0.id == id }?.name ?? Self.systemTitle
        }
    }
}
