import Foundation
import Observation

@MainActor
@Observable
final class SettingsHideHover {
    private(set) var state: State = .outside

    private var task: Task<Void, Never>?
}

extension SettingsHideHover {
    enum State: Equatable {
        case outside
        case waiting
        case armed
    }

    static let delay: TimeInterval = 0.6

    var isInside: Bool {
        state != .outside
    }

    var isArmed: Bool {
        state == .armed
    }

    func update(isInside: Bool) {
        guard isInside else {
            reset()
            return
        }

        guard state == .outside else {
            return
        }

        state = .waiting

        task = Task {
            try? await Task.sleep(for: .seconds(Self.delay))

            guard !Task.isCancelled else {
                return
            }

            state = .armed
        }
    }

    func reset() {
        task?.cancel()
        task = nil
        state = .outside
    }
}
