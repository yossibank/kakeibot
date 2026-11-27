import Core
import Store

public extension TemplateEditModel {
    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

public extension TemplateEditModel.Output {
    var amount: Int? {
        state.submodels.calculator.amount > 0 ? state.submodels.calculator.amount : nil
    }

    var typeName: String {
        state.type == .income ? "収入" : "支出"
    }

    var walletTitle: String {
        state.type == .income ? "入金先" : "支払い元"
    }

    var draft: EntryTemplateDraft {
        EntryTemplateDraft(
            name: state.fields.name,
            type: state.type,
            amount: amount,
            categoryId: state.categoryId,
            tagId: state.tagId,
            walletId: state.walletId,
            memo: state.fields.memo,
            billShift: billRecurring == nil ? 0 : state.fields.billShift
        )
    }

    var billRecurring: Recurring? {
        input.cardBills.cardBill(paidBy: state.walletId)
    }

    var categories: [EntryCategory] {
        input.options?.categories(of: state.type) ?? []
    }

    var wallets: [Wallet] {
        input.options?.wallets ?? []
    }

    var selectedCategory: EntryCategory? {
        categories.first { $0.id == state.categoryId }
    }

    var selectedWallet: Wallet? {
        wallets.first { $0.id == state.walletId }
    }

    var tags: [EntryTag] {
        input.options?.tags(of: state.categoryId, keeping: state.tagId) ?? []
    }

    var selectedTag: EntryTag? {
        tags.first { $0.id == state.tagId }
    }

    func icon(for category: EntryCategory) -> Icon? {
        input.options?.icon(for: category)
    }

    func icon(for wallet: Wallet) -> Icon? {
        input.options?.icon(for: wallet)
    }
}

extension TemplateEditModel.Output {
    var problemMessage: String? {
        draft.problems.first.map(message)
    }
}

private extension TemplateEditModel.Output {
    func message(for problem: EntryTemplateDraft.Problem) -> String {
        switch problem {
        case .emptyName: "名前を入れてください"
        case .missingCategory: "カテゴリを選んでください"
        case .missingWallet: "\(walletTitle)を選んでください"
        case .amountNotPositive, .transfer: SettingsEditMessage.saveFailed
        }
    }
}
