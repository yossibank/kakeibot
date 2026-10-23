import SwiftUI

public enum Emphasis: Double, Sendable {
    case faint = 0.06
    case subtle = 0.12
    case soft = 0.2
    case muted = 0.35
    case medium = 0.55
    case strong = 0.8
}

public extension Color {
    func opacity(_ emphasis: Emphasis) -> Color {
        opacity(emphasis.rawValue)
    }
}
