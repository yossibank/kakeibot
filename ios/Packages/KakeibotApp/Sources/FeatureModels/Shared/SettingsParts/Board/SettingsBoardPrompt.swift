public enum SettingsBoardPrompt<ID: Hashable & Sendable>: Hashable, Sendable {
    case hide(ID)
    case delete(ID)
    case deleteHidden
}

public extension SettingsBoardPrompt {
    var hidingId: ID? {
        guard case let .hide(id) = self else {
            return nil
        }

        return id
    }

    var deletingId: ID? {
        guard case let .delete(id) = self else {
            return nil
        }

        return id
    }
}
