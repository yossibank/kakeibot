import Core
import Foundation

public extension EntryModel {
    struct VoiceFilled: Equatable, Sendable {
        var walletId: Wallet.ID?
        var date: LocalDate?
        var memo: String?
    }

    struct VoiceUndo: Equatable {
        let calculator: AmountCalculator
        let date: LocalDate
        let categoryId: EntryCategory.ID?
        let tagId: EntryTag.ID?
        let walletId: Wallet.ID?
        let billMonth: YearMonth?
        let memo: String
    }

    @discardableResult
    func apply(_ reading: VoiceReading) -> VoiceUndo {
        let undo = VoiceUndo(
            calculator: state.keypad.calculator,
            date: state.payment.date,
            categoryId: state.category.id,
            tagId: state.category.tagId,
            walletId: state.payment.walletId,
            billMonth: state.payment.billMonth,
            memo: state.memo
        )

        if let amount = reading.amount,
           (1...AmountCalculator.maxValue).contains(amount) {
            state.keypad.setAmount(amount)
            state.keypad.target = .amount
        }

        if let walletId = reading.walletId {
            setWallet(walletId)
        }

        if let categoryId = reading.categoryId,
           output.categories.contains(where: { $0.id == categoryId }) {
            state.setCategory(categoryId)
        }

        if let date = reading.date {
            state.setDate(date)
        }

        if let memo = reading.memo {
            state.store = memo
        }

        state.voiceFilled = VoiceFilled(
            walletId: reading.walletId,
            date: reading.date,
            memo: reading.memo
        )

        return undo
    }

    func undo(_ undo: VoiceUndo) {
        setWallet(undo.walletId)
        state.setCategory(undo.categoryId)
        state.category.tagId = undo.tagId
        state.keypad.calculator = undo.calculator
        state.setDate(undo.date)
        state.payment.billMonth = undo.billMonth
        state.memo = undo.memo
        state.voiceFilled = nil
    }
}
