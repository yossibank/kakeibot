public enum ThemeChoice: Hashable, Sendable {
    case system
    case preset(ThemePreset)
    case custom(Theme.ID)
}

public extension ThemeChoice {
    var text: String {
        switch self {
        case .system: Self.systemText
        case let .preset(preset): preset.rawValue
        case let .custom(id): id.description
        }
    }

    init?(_ text: String) {
        if text == Self.systemText {
            self = .system
        } else if let preset = ThemePreset(rawValue: text) {
            self = .preset(preset)
        } else if let id = Theme.ID(text) {
            self = .custom(id)
        } else {
            return nil
        }
    }
}

private extension ThemeChoice {
    static let systemText = "system"
}
