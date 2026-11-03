#if DEBUG
import Core
import Store

extension SettingsMenuSampleData {
    struct Book {
        let expense: [String: EntryCategory.ID]
        let income: [String: EntryCategory.ID]
        let cash: Wallet.ID
        let bank: Wallet.ID
        let card: Wallet.ID
        let loan: Wallet.ID
    }
}

extension SettingsMenuSampleData.Book {
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
            throw SettingsMenuSampleData.SampleError.missingDefault("財布")
        }

        guard let bank = wallets["銀行"] else {
            throw SettingsMenuSampleData.SampleError.missingDefault("銀行")
        }

        self.init(expense: expense, income: income, cash: cash, bank: bank, card: card, loan: loan)
    }

    func category(
        _ name: String,
        in categories: [String: EntryCategory.ID]
    ) throws -> EntryCategory.ID {
        guard let id = categories[name] else {
            throw SettingsMenuSampleData.SampleError.missingDefault(name)
        }

        return id
    }
}
#endif
