import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel {
    @MainActor
    final class Output {
        let input: Input
        let state: State
        let monthCache = DerivedTable<LocalDate, MonthSummary>()
        let feeChoicesCache = Derived<[Int]>()
        let recentWalletsCache = Derived<[Entry.Kind: Wallet.ID]>()

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension EntryModel.Output {
    var isEditing: Bool {
        input.editingId != nil
    }

    var isLoaded: Bool {
        input.options != nil
    }

    var isChanged: Bool {
        input.baseline.map { $0 != snapshot } ?? false
    }

    var amount: Int {
        state.keypad.calculator.amount
    }

    var fee: Int {
        state.type == .transfer ? state.keypad.feeCalculator.amount : 0
    }

    var canSave: Bool {
        draft?.problems.isEmpty == true
    }

    var activeCalculator: AmountCalculator {
        state.keypad.active
    }

    var feeChoices: [Int] {
        feeChoicesCache.value {
            recentFeeChoices
        }
    }

    var expressionText: String? {
        let calculator = activeCalculator

        if let note = calculator.taxNote {
            return "\(Self.number(note.base)) の税込み \(note.rate.rawValue)%"
        }

        guard calculator.hasOperation else {
            return nil
        }

        let parts = calculator.tokens.map { token in
            switch token {
            case let .number(number): Self.number(number)
            case let .operation(operation): operation.symbol
            }
        }

        return parts.joined(separator: " ")
    }
}

extension EntryModel.Output {
    var snapshot: EntryModel.Snapshot {
        EntryModel.Snapshot(
            type: state.type,
            calculator: state.keypad.calculator,
            feeCalculator: state.keypad.feeCalculator,
            payment: state.payment,
            categoryId: state.category.id,
            tagId: state.category.tagId,
            memo: state.memo,
            items: state.items.list,
            taxIncluded: state.items.taxIncluded
        )
    }

    var draft: EntryDraft? {
        guard let walletId = state.payment.walletId else {
            return nil
        }

        let templateId = input.allTemplates
            .first { $0.id == state.appliedTemplateId && $0.type == state.type }?
            .id

        let billMonth = billChoices.isEmpty ? nil : state.payment.billMonth

        return EntryDraft(
            type: state.type,
            amount: amount,
            date: state.payment.date,
            categoryId: state.category.id,
            tagId: state.category.tagId,
            templateId: templateId,
            walletId: walletId,
            toWalletId: state.payment.toWalletId,
            memo: state.memo,
            billMonth: billMonth,
            fee: fee,
            items: showsItems ? state.items.list : [],
            taxIncluded: state.items.taxIncluded
        )
    }

    var recentFeeChoices: [Int] {
        let used = (input.history?.entries ?? [])
            .lazy
            .filter { $0.transferId != nil }
            .sorted { $0.createdAt > $1.createdAt }
            .map(\.amount)

        var seen: Set<Int> = []

        let ordered = (used + FeeChoiceRow.defaultChoices).filter { seen.insert($0).inserted }

        return Array(ordered.prefix(FeeChoiceRow.defaultChoices.count))
    }

    func label(for entry: Entry) -> String {
        let categories = categories(for: entry.type)

        return EntryChange.label(for: entry) { id in
            categories.first { $0.id == id }
        } wallet: { id in
            wallet(id)
        }
    }
}

private extension EntryModel.Output {
    static let numberLocale = Locale(identifier: "ja_JP")

    static func number(_ value: Int) -> String {
        value.formatted(.number.locale(numberLocale))
    }
}
