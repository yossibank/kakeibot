import Core
import Foundation
import Store

public extension RecordsModel {
    var batchWallets: [Wallet] {
        list?.filterWallets ?? []
    }

    func batchCategories(for type: Entry.Kind) -> [EntryCategory] {
        let categories = list?.filterCategories ?? []
        return categories.filter { $0.kind.rawValue == type.rawValue }
    }

    func batchType(of ids: Set<Entry.ID>) -> Entry.Kind? {
        let types = Set(selectedEntries(ids).map(\.type))

        guard
            types.count == 1,
            let type = types.first,
            type != .transfer
        else {
            return nil
        }

        return type
    }

    func hasTransfer(in ids: Set<Entry.ID>) -> Bool {
        selectedEntries(ids).contains { $0.type == .transfer }
    }
}

private extension RecordsModel {
    func selectedEntries(_ ids: Set<Entry.ID>) -> [Entry] {
        let entries = list?.days.flatMap(\.entries) ?? []
        return entries.filter { ids.contains($0.id) }
    }
}
