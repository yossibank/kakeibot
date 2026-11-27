import Store

@MainActor
public protocol SettingsBoardOutput {
    associatedtype Item: Identifiable
    associatedtype State: SettingsBoardState where State.ID == Item.ID

    var state: State { get }
    var items: [Item] { get }

    func isHidden(_ item: Item) -> Bool
}

public extension SettingsBoardOutput {
    internal var visible: [Item] {
        items.filter { !isHidden($0) }
    }

    var hidden: [Item] {
        items.filter { isHidden($0) }
    }

    var shown: [Item] {
        let visible = visible

        guard let movingOrder = state.fields.movingOrder else {
            return visible
        }

        return movingOrder.compactMap { id in
            visible.first { $0.id == id }
        }
    }
}

public extension SettingsBoardOutput where Item: ArchivableRow {
    func isHidden(_ item: Item) -> Bool {
        item.archivedAt != nil
    }
}
