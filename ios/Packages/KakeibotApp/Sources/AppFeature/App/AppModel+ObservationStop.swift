extension AppModel {
    struct ObservationStop: Equatable {
        private(set) var isStopped = false
    }
}

extension AppModel.ObservationStop {
    mutating func stop() {
        isStopped = true
    }

    mutating func resume() -> Bool {
        guard isStopped else {
            return false
        }

        isStopped = false

        return true
    }
}
