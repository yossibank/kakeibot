#if DEBUG
import Core
import Foundation
import Store

extension SettingsSampleData {
    static func insertBudgets(
        book: Book,
        today: LocalDate,
        into database: AppDatabase
    ) async throws {
        let month = today.yearMonth.adding(months: -4)

        let amounts: [(String?, Int)] = [
            (nil, 200_000),
            ("食費", 45000),
            ("日用品", 10000),
            ("交通", 9000),
            ("趣味", 15000)
        ]

        for (name, amount) in amounts {
            let category = try name.map { name in
                try book.category(name, in: book.expense)
            }

            try await database.setBudget(amount, for: category, from: month)
        }
    }

    static func insertRecurrings(
        book: Book,
        today: LocalDate,
        into database: AppDatabase,
        now: Date
    ) async throws {
        let start = today.adding(days: -(dayCount - 1))
        let salary = try book.category("給料", in: book.income)
        let home = try book.category("住まい", in: book.expense)
        let phone = try book.category("通信", in: book.expense)

        func draft(
            _ type: Entry.Kind,
            _ category: EntryCategory.ID?,
            _ amount: Int,
            from wallet: Wallet.ID,
            to destination: Wallet.ID? = nil,
            day: Int,
            closing: Int? = nil,
            remind: Int? = nil,
            _ memo: String
        ) -> RecurringDraft {
            RecurringDraft(
                type: type,
                amount: amount,
                categoryId: category,
                walletId: wallet,
                toWalletId: destination,
                memo: memo,
                frequency: .monthly,
                month: start.month,
                day: day,
                closingDay: closing,
                startDate: start,
                remindDaysBefore: remind
            )
        }

        let drafts = [
            draft(
                .expense,
                phone,
                4800,
                from: book.card,
                day: 10,
                "スマホ"
            ),
            draft(
                .income,
                salary,
                280_000,
                from: book.bank,
                day: 25,
                "給料"
            ),
            draft(
                .transfer,
                nil,
                0,
                from: book.bank,
                to: book.card,
                day: 26,
                closing: 15,
                remind: 1,
                "カード"
            ),
            draft(
                .expense,
                home,
                78000,
                from: book.bank,
                day: 27,
                remind: 3,
                "家賃"
            ),
            draft(
                .transfer,
                nil,
                15000,
                from: book.bank,
                to: book.loan,
                day: 27,
                "奨学金の返済"
            )
        ]

        for draft in drafts {
            try await database.saveRecurring(draft, today: today, at: now)
        }
    }

    static func insertTemplates(
        book: Book,
        into database: AppDatabase,
        now: Date
    ) async throws {
        let food = try book.category("食費", in: book.expense)
        let transit = try book.category("交通", in: book.expense)

        let drafts = [
            EntryTemplateDraft(
                name: "ランチ",
                type: .expense,
                amount: 900,
                categoryId: food,
                walletId: book.cash
            ),
            EntryTemplateDraft(
                name: "コーヒー",
                type: .expense,
                amount: 380,
                categoryId: food,
                walletId: book.cash
            ),
            EntryTemplateDraft(
                name: "電車",
                type: .expense,
                amount: 440,
                categoryId: transit,
                walletId: book.cash
            ),
            EntryTemplateDraft(
                name: "スーパー",
                type: .expense,
                amount: nil,
                categoryId: food,
                walletId: book.card
            )
        ]

        for draft in drafts {
            try await database.saveTemplate(draft, at: now)
        }
    }
}
#endif
