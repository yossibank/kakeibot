public extension SyncModel {
    struct SwitchRequest: Equatable, Sendable {
        public private(set) var isOn: Bool?

        public init() {}
    }
}

public extension SyncModel.SwitchRequest {
    var isPending: Bool {
        isOn != nil
    }

    mutating func ask(_ isOn: Bool) {
        self.isOn = isOn
    }

    mutating func clear() {
        isOn = nil
    }
}
