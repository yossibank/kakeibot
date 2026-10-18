import SwiftUI

public extension Color {
    func opacity(_ emphasis: Emphasis) -> Color {
        opacity(emphasis.rawValue)
    }
}
