#if DEBUG
import Core
import Foundation
import Store

enum SettingsMenuSampleData {
    enum SampleError: Error {
        case missingDefault(String)
    }

    private struct Day {
        let drafts: [EntryDraft]
        let isNoSpend: Bool
    }

    private typealias Purchase = (
        isMade: Bool,
        name: String,
        amount: Int,
        wallet: Wallet.ID,
        memo: String
    )

    static let dayCount = 120

    private static var cardDraft: WalletDraft {
        WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#7E89A0",
            initialBalance: 0
        )
    }

    private static var investmentDraft: WalletDraft {
        WalletDraft(
            kind: .investment,
            name: "つみたて",
            mark: .glyph(.invest),
            color: "#5C9A7A",
            initialBalance: 360_000
        )
    }

    private static var loanDraft: WalletDraft {
        WalletDraft(
            kind: .loan,
            name: "奨学金",
            mark: .glyph(.contract),
            color: "#8A7FA8",
            initialBalance: -1_200_000
        )
    }

    static func insert(
        into database: AppDatabase,
        today: LocalDate,
        now: Date
    ) async throws {
        let card = try await database.save(cardDraft, at: now)

        _ = try await database.save(investmentDraft, at: now)

        let loan = try await database.save(loanDraft, at: now)
        let options = try await database.entryOptions()
        let book = try Book(options: options, card: card.id, loan: loan.id)
        var drafts: [EntryDraft] = []
        var noSpendDays: [LocalDate] = []

        for offset in (0..<dayCount).reversed() {
            let date = today.adding(days: -offset)
            let day = try plan(date, today: today, book: book)

            drafts += day.drafts

            if day.isNoSpend {
                noSpendDays.append(date)
            }
        }

        try await database.saveEntries(drafts, at: now)
        try await database.markNoSpendDays(noSpendDays, at: now)
        try await insertBudgets(book: book, today: today, into: database)
        try await insertTemplates(book: book, into: database, now: now)
        try await insertRecurrings(book: book, today: today, into: database, now: now)
    }

    private static func plan(
        _ date: LocalDate,
        today: LocalDate,
        book: Book
    ) throws -> Day {
        let seed = date.year * 400 + date.month * 32 + date.day
        let isNoSpend = seed % 9 == 0
        var drafts = try fixedDrafts(on: date, today: today, book: book)

        if !isNoSpend {
            drafts += try dailyDrafts(on: date, seed: seed, book: book)
        }

        let hasExpense = drafts.contains { $0.type == .expense }

        return Day(drafts: drafts, isNoSpend: isNoSpend && !hasExpense)
    }

    private static func dailyDrafts(
        on date: LocalDate,
        seed: Int,
        book: Book
    ) throws -> [EntryDraft] {
        let isWeekday = date.weekday != .saturday && date.weekday != .sunday

        let purchases: [Purchase] = [
            (isWeekday, "食費", 700 + seed % 6 * 100, book.cash, "ランチ"),
            (isWeekday, "交通", 440, book.cash, "電車"),
            (seed % 4 == 2, "食費", 380, book.cash, "コーヒー"),
            (seed % 3 == 0, "食費", 1800 + seed % 17 * 100, book.card, "スーパー"),
            (seed % 6 == 1, "日用品", 900 + seed % 13 * 100, book.card, "ドラッグストア"),
            (seed % 10 == 4, "交際", 3500 + seed % 5 * 500, book.cash, "飲み会"),
            (seed % 13 == 7, "趣味", 2500 + seed % 7 * 600, book.card, "本"),
            (seed % 29 == 11, "衣服", 6800, book.card, "シャツ"),
            (seed % 31 == 5, "美容", 4500, book.cash, "美容院"),
            (seed % 47 == 20, "医療", 1800, book.cash, "通院")
        ]

        return try purchases.filter(\.isMade).map { purchase in
            let category = try book.category(purchase.name, in: book.expense)

            return EntryDraft(
                type: .expense,
                amount: purchase.amount,
                date: date,
                categoryId: category,
                walletId: purchase.wallet,
                memo: purchase.memo
            )
        }
    }

    private static func fixedDrafts(
        on date: LocalDate,
        today: LocalDate,
        book: Book
    ) throws -> [EntryDraft] {
        var drafts: [EntryDraft] = []

        func add(
            _ type: Entry.Kind,
            _ category: EntryCategory.ID?,
            _ amount: Int,
            from wallet: Wallet.ID,
            to destination: Wallet.ID? = nil,
            _ memo: String
        ) {
            let draft = EntryDraft(
                type: type,
                amount: amount,
                date: date,
                categoryId: category,
                walletId: wallet,
                toWalletId: destination,
                memo: memo
            )

            drafts.append(draft)
        }

        let bonus = try book.category("臨時収入", in: book.income)
        let utility = try book.category("光熱費", in: book.expense)
        let utilityAmount = 6200 + date.month % 3 * 900

        if date.day == 15 {
            add(.expense, utility, utilityAmount, from: book.bank, "電気・ガス")
        }

        if date.weekday == .monday {
            add(.transfer, nil, 10000, from: book.bank, to: book.cash, "ATM")
        }

        if date == today.adding(days: -52) {
            add(.income, bonus, 30000, from: book.bank, "臨時収入")
        }

        return drafts
    }
}
#endif
