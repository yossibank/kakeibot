import SwiftUI

struct ForegroundReturn {
    private var wasBackground = false
}

extension ForegroundReturn {
    mutating func receive(_ phase: ScenePhase) -> Bool {
        switch phase {
        case .background:
            wasBackground = true
            return false
        case .active:
            defer {
                wasBackground = false
            }

            return wasBackground
        default:
            return false
        }
    }
}
