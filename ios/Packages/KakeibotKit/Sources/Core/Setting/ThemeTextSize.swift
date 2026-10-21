public enum ThemeTextSize: String, CaseIterable, Codable, Sendable {
    case small
    case standard
    case large
}

public extension ThemeTextSize {
    var scale: Double {
        switch self {
        case .small: 0.9
        case .standard: 1
        case .large: 1.15
        }
    }
}
