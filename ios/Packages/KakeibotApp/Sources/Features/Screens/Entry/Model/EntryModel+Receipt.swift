import Core
import Foundation

public extension EntryModel {
    static let freeReceiptLimit = 3
    static let receiptCountFailedMessage = "記録は保存しましたが、レシートの回数を数えられませんでした"
    static let itemNameFailedMessage = "記録は保存しましたが、直した品名を覚えられませんでした"

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

    @discardableResult
    func apply(_ reading: ReceiptReading) async -> Bool {
        let store = reading.store?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let names = await rememberedNames(at: store)
        let renamed = reading.renamed(by: names)
        var setsAmount = false

        if renamed.items.isEmpty {
            forgetReadNames()
        } else {
            items = renamed.items
            taxIncluded = renamed.taxIncluded
        }

        if let total = renamed.total,
           (1...AmountCalculator.maxValue).contains(total) {
            calculator = AmountCalculator(amount: total)
            setsAmount = true
        } else if !renamed.items.isEmpty, canAdjustToItems {
            adjustToItems()
            setsAmount = itemTotal > 0
        }

        if let date = renamed.date {
            self.date = date
        }

        if !store.isEmpty {
            self.store = store
        }

        receiptStore = store.isEmpty ? nil : store
        isReceiptRead = true

        return setsAmount
    }
}

extension EntryModel {
    func finishReceipt() async {
        guard showsItems else {
            isReceiptRead = false
            return
        }

        await rememberItemNames()

        guard isReceiptRead else {
            return
        }

        isReceiptRead = false

        do {
            try await database.countReceiptSave()
            receiptSavedCount += 1
        } catch {
            errorNotice.show(Self.receiptCountFailedMessage)
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
        guard let store = receiptStore else {
            return
        }

        let now = Date()

        for item in items {
            guard let read = item.readName else {
                continue
            }

            do {
                if item.trimmedName == read {
                    try await database.forgetItemName(for: read, at: store)
                } else {
                    try await database.rememberItemName(
                        item.trimmedName,
                        for: read,
                        at: store,
                        on: now
                    )
                }
            } catch {
                errorNotice.show(Self.itemNameFailedMessage)
                return
            }
        }
    }

    func forgetReadNames() {
        for index in items.indices {
            items[index].readName = nil
        }
    }
}
