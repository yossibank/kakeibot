public enum ThemeChoice: Hashable, Sendable {
    case preset(ThemePreset)
    case custom(Theme.ID)
}

public extension ThemeChoice {
    init?(_ text: String) {
        if let preset = ThemePreset(rawValue: text) {
            self = .preset(preset)
        } else if let id = Theme.ID(text) {
            self = .custom(id)
        } else {
            return nil
        }
    }

    var text: String {
        switch self {
        case let .preset(preset): preset.rawValue
        case let .custom(id): id.description
        }
    }
}
