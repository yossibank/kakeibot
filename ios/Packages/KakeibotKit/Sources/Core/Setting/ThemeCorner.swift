public enum ThemeCorner: Int, CaseIterable, Codable, Sendable {
    case small = 60
    case standard = 100
    case large = 140
}

public extension ThemeCorner {
    var scale: Double {
        Double(rawValue) / 100
    }
}
