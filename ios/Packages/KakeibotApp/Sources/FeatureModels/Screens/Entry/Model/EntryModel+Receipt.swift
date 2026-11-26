import Core
import Foundation

public extension EntryModel {
    static let freeReceiptLimit = 3
    static let receiptCountFailedMessage = "記録は保存しましたが、レシートの回数を数えられませんでした"
    static let itemNameFailedMessage = "記録は保存しましたが、直した品名を覚えられませんでした"

    @discardableResult
    func apply(_ reading: ReceiptReading) async -> Bool {
        let store = reading.store?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let names = await rememberedNames(at: store)
        let renamed = reading.renamed(by: names)
        var setsAmount = false

        if renamed.items.isEmpty {
            state.items.forgetReadNames()
        } else {
            state.items.list = renamed.items
            state.items.taxIncluded = renamed.taxIncluded
        }

        let adjusts = !renamed.items.isEmpty && state.items.canAdjust

        if let total = renamed.total,
           (1...AmountCalculator.maxValue).contains(total) {
            state.keypad.setAmount(total)
            setsAmount = true
        } else if adjusts {
            state.adjustToItems()
            setsAmount = output.itemTotal > 0
        }

        if let date = renamed.date {
            state.setDate(date)
        }

        if !store.isEmpty {
            state.fields.store = store
        }

        state.items.receiptStore = store.isEmpty ? nil : store
        state.items.isReceiptRead = true

        return setsAmount
    }
}

extension EntryModel {
    func hideReceiptGuide() async {
        do {
            try await dependencies.database.setSetting(.receiptGuideHidden, to: true)
            input.receiptGuideHidden = true
        } catch {
            report(error)
        }
    }

    func finishReceipt() async {
        guard output.showsItems else {
            state.items.isReceiptRead = false
            return
        }

        await rememberItemNames()

        guard state.items.isReceiptRead else {
            return
        }

        state.items.isReceiptRead = false

        do {
            try await dependencies.database.countReceiptSave()
            input.receiptSavedCount += 1
        } catch {
            state.errorNotice.show(Self.receiptCountFailedMessage)
        }
    }
}

private extension EntryModel {
    func rememberedNames(at store: String) async -> [String: String] {
        guard !store.isEmpty else {
            return [:]
        }

        do {
            return try await dependencies.database.itemNames(at: store)
        } catch {
            report(error)
            return [:]
        }
    }

    func rememberItemNames() async {
        guard let store = state.items.receiptStore else {
            return
        }

        let now = dependencies.clock.now

        for item in state.items.list {
            guard let read = item.readName else {
                continue
            }

            do {
                if item.trimmedName == read {
                    try await dependencies.database.forgetItemName(for: read, at: store)
                } else {
                    try await dependencies.database.rememberItemName(
                        item.trimmedName,
                        for: read,
                        at: store,
                        on: now
                    )
                }
            } catch {
                state.errorNotice.show(Self.itemNameFailedMessage)
                return
            }
        }
    }
}
