import Store

@MainActor
protocol SettingsBoardOutput {
    associatedtype Item: Identifiable
    associatedtype State: SettingsBoardState where State.ID == Item.ID

    var state: State { get }
    var items: [Item] { get }

    func isHidden(_ item: Item) -> Bool
}

extension SettingsBoardOutput {
    var visible: [Item] {
        items.filter { !isHidden($0) }
    }

    var hidden: [Item] {
        items.filter { isHidden($0) }
    }

    var shown: [Item] {
        let visible = visible

        guard let movingOrder = state.movingOrder else {
            return visible
        }

        return movingOrder.compactMap { id in
            visible.first { $0.id == id }
        }
    }
}

extension SettingsBoardOutput where Item: ArchivableRecord {
    func isHidden(_ item: Item) -> Bool {
        item.archivedAt != nil
    }
}
