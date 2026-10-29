#if DEBUG
import Core
import Store

extension SampleData {
    struct Book {
        let expense: [String: EntryCategory.ID]
        let income: [String: EntryCategory.ID]
        let cash: Wallet.ID
        let bank: Wallet.ID
        let card: Wallet.ID
        let loan: Wallet.ID
    }
}

extension SampleData.Book {
    init(
        options: EntryOptions,
        card: Wallet.ID,
        loan: Wallet.ID
    ) throws {
        let expense = Dictionary(
            options.expenseCategories.map { ($0.name, $0.id) },
            uniquingKeysWith: { first, _ in first }
        )

        let income = Dictionary(
            options.incomeCategories.map { ($0.name, $0.id) },
            uniquingKeysWith: { first, _ in first }
        )

        let wallets = Dictionary(
            options.wallets.map { ($0.name, $0.id) },
            uniquingKeysWith: { first, _ in first }
        )

        guard let cash = wallets["財布"] else {
            throw SampleData.SampleError.missingDefault("財布")
        }

        guard let bank = wallets["銀行"] else {
            throw SampleData.SampleError.missingDefault("銀行")
        }

        self.init(expense: expense, income: income, cash: cash, bank: bank, card: card, loan: loan)
    }

    func category(
        _ name: String,
        in categories: [String: EntryCategory.ID]
    ) throws -> EntryCategory.ID {
        guard let id = categories[name] else {
            throw SampleData.SampleError.missingDefault(name)
        }

        return id
    }
}
#endif
