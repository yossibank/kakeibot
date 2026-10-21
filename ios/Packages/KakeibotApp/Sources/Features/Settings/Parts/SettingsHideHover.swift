import Foundation
import Observation

@MainActor
@Observable
final class SettingsHideHover {
    private(set) var state: State = .outside
}

extension SettingsHideHover {
    enum State: Equatable {
        case outside
        case armed
    }

    var isInside: Bool {
        state != .outside
    }

    var isArmed: Bool {
        state == .armed
    }

    func update(isInside: Bool) {
        state = isInside ? .armed : .outside
    }

    func reset() {
        state = .outside
    }
}
