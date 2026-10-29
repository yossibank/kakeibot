public enum ThemeCorner: String, CaseIterable, Codable, Sendable {
    case square
    case small
    case standard
    case large

    public var scale: Double {
        switch self {
        case .square: 0
        case .small: 0.6
        case .standard: 1
        case .large: 1.4
        }
    }
}
