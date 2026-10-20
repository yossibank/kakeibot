public enum ThemeCorner: String, CaseIterable, Codable, Sendable {
    case small
    case standard
    case large
}

public extension ThemeCorner {
    var scale: Double {
        switch self {
        case .small: 0.6
        case .standard: 1
        case .large: 1.4
        }
    }
}
