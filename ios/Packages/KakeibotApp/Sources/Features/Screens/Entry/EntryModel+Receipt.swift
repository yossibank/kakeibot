import Core
import Foundation

public extension EntryModel {
    static let freeReceiptLimit = 3

    var showsReceipt: Bool {
        showsItems && keypadTarget == .amount
    }

    var showsReceiptGuide: Bool {
        receiptSavedCount == 0
    }

    var freeReceiptsLeft: Int {
        max(Self.freeReceiptLimit - receiptSavedCount, 0)
    }

    var suspectItemIndices: Set<Int> {
        guard items.contains(where: { $0.readName != nil }) else {
            return []
        }

        return Set(ReceiptSuspect.indices(of: items, difference: itemAdjustment))
    }

    func canReadReceipt(isPro: Bool) -> Bool {
        isPro || receiptSavedCount < Self.freeReceiptLimit
    }

    func apply(_ reading: ReceiptReading) async {
        let store = reading.store?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let names = await rememberedNames(at: store)
        let renamed = reading.renamed(by: names)

        if !renamed.items.isEmpty {
            items = renamed.items
        }

        if let total = renamed.total,
           (1...AmountCalculator.maxValue).contains(total) {
            calculator = AmountCalculator(amount: total)
        } else if !renamed.items.isEmpty {
            adjustToItems()
        }

        if let date = renamed.date {
            self.date = date
        }

        if !store.isEmpty {
            self.store = store
        }

        isReceiptRead = true
    }
}

extension EntryModel {
    func finishReceipt() async {
        await rememberItemNames()

        guard isReceiptRead else {
            return
        }

        isReceiptRead = false

        do {
            try await database.countReceiptSave()
            receiptSavedCount += 1
        } catch {
            report(error)
        }
    }
}

private extension EntryModel {
    func rememberedNames(at store: String) async -> [String: String] {
        guard !store.isEmpty else {
            return [:]
        }

        do {
            return try await database.itemNames(at: store)
        } catch {
            report(error)
            return [:]
        }
    }

    func rememberItemNames() async {
        let store = store.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            showsItems,
            !store.isEmpty
        else {
            return
        }

        let now = Date()

        for item in items {
            guard
                let read = item.readName,
                item.trimmedName != read
            else {
                continue
            }

            do {
                try await database.rememberItemName(
                    item.trimmedName,
                    for: read,
                    at: store,
                    on: now
                )
            } catch {
                report(error)
                return
            }
        }
    }
}
