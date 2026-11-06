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

    func batchCategoryBlock(of ids: Set<Entry.ID>) -> String? {
        let types = Set(selectedEntries(ids).map(\.type))

        if types.isEmpty {
            return Self.emptySelectionBlock
        }

        if types.contains(.transfer) {
            return "振替を含むので、カテゴリはまとめて変えられません"
        }

        if types.count > 1 {
            return "支出と収入が混ざっているので、カテゴリはまとめて変えられません"
        }

        return nil
    }

    func batchWalletBlock(of ids: Set<Entry.ID>) -> String? {
        let types = Set(selectedEntries(ids).map(\.type))

        if types.isEmpty {
            return Self.emptySelectionBlock
        }

        if types.contains(.transfer) {
            return "振替を含むので、口座はまとめて変えられません"
        }

        return nil
    }

    func batchDeleteBlock(of ids: Set<Entry.ID>) -> String? {
        ids.isEmpty ? Self.emptySelectionBlock : nil
    }
}

private extension RecordsModel {
    static let emptySelectionBlock = "記録を選んでください"
}

private extension RecordsModel {
    func selectedEntries(_ ids: Set<Entry.ID>) -> [Entry] {
        let entries = list?.days.flatMap(\.entries) ?? []
        return entries.filter { ids.contains($0.id) }
    }
}
