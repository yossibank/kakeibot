import Core
import GRDB

public extension AppDatabase {
    enum BudgetWriteError: Error, Equatable {
        case amountNotPositive
    }

    func setBudget(
        _ amount: Int?,
        for categoryId: EntryCategory.ID?,
        from month: YearMonth
    ) async throws {
        if let amount, amount < 1 {
            throw BudgetWriteError.amountNotPositive
        }

        try await writer.write { db in
            let budgets = try Self.budgets(in: db)

            let existing = budgets.first { budget in
                budget.categoryId == categoryId && budget.fromMonth == month
            }

            let others = budgets.filter { $0.id != existing?.id }

            guard others.amount(for: categoryId, in: month) != amount else {
                if let existing {
                    _ = try existing.delete(db)
                }

                return
            }

            var budget = existing ?? Budget(
                categoryId: categoryId,
                fromMonth: month,
                amount: amount
            )

            budget.amount = amount
            try budget.save(db)
        }
    }
}
