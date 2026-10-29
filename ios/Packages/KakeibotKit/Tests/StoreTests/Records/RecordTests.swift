import Core
import Foundation
import GRDB
import Store
import Testing

struct RecordTests {
    @Test
    func roundTripsEveryTable() throws {
        let database = try AppDatabase.inMemory()
        let sample = try Sample()

        try database.writer.write { db in
            try sample.insert(into: db)
        }

        let stored = try database.writer.read { db in
            try Tables(fetchingFrom: db)
        }

        #expect(stored == sample.tables)
    }

    @Test
    func storesValuesAsText() throws {
        let database = try AppDatabase.inMemory()
        let sample = try Sample()

        try database.writer.write { db in
            try sample.insert(into: db)
        }

        let row = try database.writer.read { db in
            try Row.fetchOne(db, sql: Self.expenseQuery)
        }

        #expect(row?["id"] == sample.expense.id.description)
        #expect(row?["type"] == "expense")
        #expect(row?["date"] == "2026-02-27")
        #expect(row?["created_at"] == "2026-10-03T04:00:00Z")
    }

    @Test(arguments: [
        ("2026-10-29T02:32:29Z", 1_793_241_149.0),
        ("2026-10-29T11:32:29+09:00", 1_793_241_149.0),
        ("2026-10-29T02:32:29.250Z", 1_793_241_149.25)
    ])
    func readsStoredTimes(
        text: String,
        seconds: TimeInterval
    ) throws {
        let database = try AppDatabase.inMemory()
        let sample = try Sample()

        try database.writer.write { db in
            try sample.insert(into: db)
            try db.execute(sql: Self.expenseTimeUpdate, arguments: [text])
        }

        let entry = try database.writer.read { db in
            try Entry.fetchOne(db, key: sample.expense.id)
        }

        #expect(entry?.createdAt == Date(timeIntervalSince1970: seconds))
    }

    @Test
    func acceptsValidEntry() throws {
        let database = try AppDatabase.inMemory()
        let sample = try Sample()

        let entry = sample.entry(type: .expense, categoryId: sample.category.id, toWalletId: nil)

        try database.writer.write { db in
            try sample.insert(into: db)
        }

        try database.writer.write { db in
            try entry.insert(db)
        }

        let count = try database.writer.read { db in
            try Entry.fetchCount(db)
        }

        #expect(count == 3)
    }

    @Test(arguments: InvalidRow.allCases)
    func rejectsInvalidRow(invalid: InvalidRow) throws {
        let database = try AppDatabase.inMemory()
        let sample = try Sample()

        try database.writer.write { db in
            try sample.insert(into: db)
        }

        #expect(throws: DatabaseError.self) {
            try database.writer.write { db in
                try invalid.record(alongside: sample).insert(db)
            }
        }
    }
}

extension RecordTests {
    enum InvalidRow: CaseIterable, Sendable {
        case expenseWithoutCategory
        case transferWithCategory
        case transferToSameWallet
        case zeroAmount
        case duplicateRecurringDate
        case unknownWallet
        case secondWholeMonthBudget
        case duplicateRewardLog
        case iconWithoutEmojiOrText

        func record(alongside sample: RecordTests.Sample) -> any PersistableRecord {
            switch self {
            case .expenseWithoutCategory:
                sample.entry(
                    type: .expense,
                    categoryId: nil,
                    toWalletId: nil
                )
            case .transferWithCategory:
                sample.entry(
                    type: .transfer,
                    categoryId: sample.category.id,
                    toWalletId: sample.cash.id
                )
            case .transferToSameWallet:
                sample.entry(
                    type: .transfer,
                    categoryId: nil,
                    toWalletId: sample.bank.id
                )
            case .zeroAmount:
                sample.entry(
                    type: .expense,
                    categoryId: sample.category.id,
                    toWalletId: nil,
                    amount: 0
                )
            case .duplicateRecurringDate:
                sample.entry(
                    type: .expense,
                    categoryId: sample.category.id,
                    toWalletId: nil,
                    recurringId: sample.recurring.id,
                    recurringDate: sample.expense.recurringDate
                )
            case .unknownWallet:
                sample.entry(
                    type: .expense,
                    categoryId: sample.category.id,
                    toWalletId: nil,
                    walletId: Wallet.ID()
                )
            case .secondWholeMonthBudget:
                Budget(
                    categoryId: nil,
                    fromMonth: sample.wholeBudget.fromMonth,
                    amount: 1
                )
            case .duplicateRewardLog:
                RewardLog(
                    ruleId: sample.rule.id,
                    date: sample.rewardLog.date,
                    amount: 1,
                    createdAt: sample.now
                )
            case .iconWithoutEmojiOrText:
                Icon(
                    emoji: nil,
                    text: nil,
                    color: "#000000",
                    createdAt: sample.now,
                    updatedAt: sample.now
                )
            }
        }
    }

    struct Tables: Equatable {
        let icons: Set<Icon>
        let shelfIcons: Set<ShelfIcon>
        let wallets: Set<Wallet>
        let categories: Set<EntryCategory>
        let recurrings: Set<Recurring>
        let entries: Set<Entry>
        let budgets: Set<Budget>
        let rewardRules: Set<RewardRule>
        let rewardLogs: Set<RewardLog>
        let rewardGoals: Set<RewardGoal>
        let calendarStamps: Set<CalendarStamp>
        let noSpendDays: Set<NoSpendDay>
        let themes: Set<Theme>
        let settings: Set<Setting>
    }

    struct Sample {
        let now: Date
        let icon: Icon
        let shelfIcon: ShelfIcon
        let cash: Wallet
        let bank: Wallet
        let loan: Wallet
        let category: EntryCategory
        let recurring: Recurring
        let expense: Entry
        let transfer: Entry
        let wholeBudget: Budget
        let categoryBudget: Budget
        let rule: RewardRule
        let rewardLog: RewardLog
        let goal: RewardGoal
        let stamp: CalendarStamp
        let noSpendDay: NoSpendDay
        let theme: Theme
        let settings: [Setting]
    }
}

extension RecordTests.Tables {
    init(fetchingFrom db: Database) throws {
        try self.init(
            icons: Set(Icon.fetchAll(db)),
            shelfIcons: Set(ShelfIcon.fetchAll(db)),
            wallets: Set(Wallet.fetchAll(db)),
            categories: Set(EntryCategory.fetchAll(db)),
            recurrings: Set(Recurring.fetchAll(db)),
            entries: Set(Entry.fetchAll(db)),
            budgets: Set(Budget.fetchAll(db)),
            rewardRules: Set(RewardRule.fetchAll(db)),
            rewardLogs: Set(RewardLog.fetchAll(db)),
            rewardGoals: Set(RewardGoal.fetchAll(db)),
            calendarStamps: Set(CalendarStamp.fetchAll(db)),
            noSpendDays: Set(NoSpendDay.fetchAll(db)),
            themes: Set(Theme.fetchAll(db)),
            settings: Set(Setting.fetchAll(db))
        )
    }
}

private extension RecordTests {
    static let expenseQuery = "SELECT * FROM entry WHERE type = 'expense'"
    static let expenseTimeUpdate = "UPDATE entry SET created_at = ? WHERE type = 'expense'"
}
