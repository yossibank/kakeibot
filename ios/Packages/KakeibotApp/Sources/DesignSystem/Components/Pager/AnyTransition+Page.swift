import SwiftUI

public extension AnyTransition {
    static func page(forward: Bool) -> AnyTransition {
        let insertion: Edge = forward ? .trailing : .leading
        let removal: Edge = forward ? .leading : .trailing

        return .asymmetric(
            insertion: .move(edge: insertion).combined(with: .opacity),
            removal: .move(edge: removal).combined(with: .opacity)
        )
    }
}
