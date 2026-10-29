public enum ThemeRowSpacing: String, CaseIterable, Codable, Sendable {
    case compact
    case standard
    case relaxed

    public var padding: Double {
        switch self {
        case .compact: 4
        case .standard: 8
        case .relaxed: 12
        }
    }

    public var minHeight: Double {
        switch self {
        case .compact: 40
        case .standard: 48
        case .relaxed: 56
        }
    }
}
