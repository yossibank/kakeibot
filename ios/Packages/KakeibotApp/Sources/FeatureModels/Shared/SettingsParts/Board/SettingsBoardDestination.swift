public enum SettingsBoardDestination<ID: Hashable & Sendable>: Hashable, Sendable {
    case new
    case edit(ID)
}

public extension SettingsBoardDestination {
    var editingID: ID? {
        switch self {
        case .new: nil
        case let .edit(id): id
        }
    }
}
