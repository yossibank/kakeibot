#if DEBUG
import Core
import Foundation
import Store

enum SampleData {}

extension SampleData {
    enum SampleError: Error {
        case missingDefault(String)
    }

    static let dayCount = 120

    static func insert(
        into database: AppDatabase,
        today: LocalDate,
        now: Date
    ) async throws {
        let card = try await database.saveWallet(cardDraft, at: now)
        _ = try await database.saveWallet(investmentDraft, at: now)
        let loan = try await database.saveWallet(loanDraft, at: now)
        let options = try await database.entryOptions()

        let book = try Book(
            options: options,
            card: card.id,
            loan: loan.id
        )

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
        try await insertRecurrings(
            book: book,
            today: today,
            into: database,
            now: now
        )
    }
}

private extension SampleData {
    struct Day {
        let drafts: [EntryDraft]
        let isNoSpend: Bool
    }

    struct Book {
        let expense: [String: EntryCategory.ID]
        let income: [String: EntryCategory.ID]
        let cash: Wallet.ID
        let bank: Wallet.ID
        let card: Wallet.ID
        let loan: Wallet.ID
    }

    static var cardDraft: WalletDraft {
        WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#7E89A0",
            initialBalance: 0
        )
    }

    static var investmentDraft: WalletDraft {
        WalletDraft(
            kind: .investment,
            name: "つみたて",
            mark: .glyph(.invest),
            color: "#5C9A7A",
            initialBalance: 360_000
        )
    }

    static var loanDraft: WalletDraft {
        WalletDraft(
            kind: .loan,
            name: "奨学金",
            mark: .glyph(.contract),
            color: "#8A7FA8",
            initialBalance: -1_200_000
        )
    }

    static func plan(
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

    static func dailyDrafts(
        on date: LocalDate,
        seed: Int,
        book: Book
    ) throws -> [EntryDraft] {
        let isWeekday = date.weekday != .saturday && date.weekday != .sunday
        var drafts: [EntryDraft] = []

        func add(
            _ name: String,
            _ amount: Int,
            _ wallet: Wallet.ID,
            _ memo: String
        ) throws {
            let category = try book.category(name, in: book.expense)

            let draft = EntryDraft(
                type: .expense,
                amount: amount,
                date: date,
                categoryId: category,
                walletId: wallet,
                memo: memo
            )

            drafts.append(draft)
        }

        if isWeekday {
            try add("食費", 700 + seed % 6 * 100, book.cash, "ランチ")
            try add("交通", 440, book.cash, "電車")
        }

        if seed % 4 == 2 {
            try add("食費", 380, book.cash, "コーヒー")
        }

        if seed % 3 == 0 {
            try add("食費", 1800 + seed % 17 * 100, book.card, "スーパー")
        }

        if seed % 6 == 1 {
            try add("日用品", 900 + seed % 13 * 100, book.card, "ドラッグストア")
        }

        if seed % 10 == 4 {
            try add("交際", 3500 + seed % 5 * 500, book.cash, "飲み会")
        }

        if seed % 13 == 7 {
            try add("趣味", 2500 + seed % 7 * 600, book.card, "本")
        }

        if seed % 29 == 11 {
            try add("衣服", 6800, book.card, "シャツ")
        }

        if seed % 31 == 5 {
            try add("美容", 4500, book.cash, "美容院")
        }

        if seed % 47 == 20 {
            try add("医療", 1800, book.cash, "通院")
        }

        return drafts
    }

    static func fixedDrafts(
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
            draft(.expense, phone, 4800, from: book.card, day: 10, "スマホ"),
            draft(.income, salary, 280_000, from: book.bank, day: 25, "給料"),
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

private extension SampleData.Book {
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

        self.init(
            expense: expense,
            income: income,
            cash: cash,
            bank: bank,
            card: card,
            loan: loan
        )
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
