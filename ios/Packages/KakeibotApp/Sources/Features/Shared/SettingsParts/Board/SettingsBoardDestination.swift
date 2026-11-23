enum SettingsBoardDestination<ID: Hashable>: Hashable {
    case new
    case edit(ID)
}

extension SettingsBoardDestination {
    var editingID: ID? {
        switch self {
        case .new: nil
        case let .edit(id): id
        }
    }
}
