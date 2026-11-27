extension AppModel {
    struct Reveal: Equatable {
        private(set) var curtain: Curtain = .covering
        private(set) var hasSwept = false
        private(set) var isHomeLoaded = false
    }
}

extension AppModel.Reveal {
    mutating func finishSweep() {
        hasSwept = true
    }

    mutating func leaveCurtain() {
        curtain = .leaving
    }

    mutating func finishCurtain() {
        curtain = .finished
    }

    mutating func markHomeLoaded() {
        isHomeLoaded = true
    }
}
