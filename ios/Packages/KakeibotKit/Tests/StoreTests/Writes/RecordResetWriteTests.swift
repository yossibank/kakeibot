import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct RecordResetWriteTests {
    @Test
    func deletesOwnRecords() async throws {
        let setup = try await Setup()
        try await setup.addOwnRecords()

        try await setup.database.deleteAllRecords(at: setup.now)

        #expect(try await setup.count("entry") == 0)
        #expect(try await setup.count("valuation") == 0)
        #expect(try await setup.count("reward_log") == 0)
        #expect(try await setup.count("calendar_stamp") == 0)
        #expect(try await setup.count("no_spend_day") == 0)
    }

    @Test
    func keepsRecordsOfSharedWallet() async throws {
        let setup = try await Setup()
        try await setup.addOwnRecords()
        try await setup.addSharedRecords()

        try await setup.database.deleteAllRecords(at: setup.now)

        #expect(try await setup.count("entry") == 3)
        #expect(try await setup.count("entry WHERE transfer_id IS NOT NULL") == 1)
        #expect(try await setup.count("valuation") == 1)
        #expect(try await setup.count("entry WHERE wallet_id = '\(setup.shared)'") == 1)
        #expect(try await setup.count("entry WHERE to_wallet_id = '\(setup.shared)'") == 1)
        #expect(try await setup.count("valuation WHERE wallet_id = '\(setup.shared)'") == 1)
    }

    @Test
    func keepsSettingsAndPlans() async throws {
        let setup = try await Setup()
        let tables = ["wallet", "category", "tag", "budget", "template", "recurring", "setting"]
        try await setup.addOwnRecords()
        let before = try await setup.counts(of: tables)

        try await setup.database.deleteAllRecords(at: setup.now)
        let after = try await setup.counts(of: tables)

        #expect(after == before)
        #expect(try await setup.count("reward_rule") == 1)
    }

    @Test
    func detachesRewardGoals() async throws {
        let setup = try await Setup()
        let entry = try await setup.addOwnRecords()
        let draft = RewardGoalDraft(name: "靴", targetAmount: 600)
        let goal = try await setup.database.saveRewardGoal(draft, at: setup.now)
        try await setup.execute("UPDATE reward_goal SET entry_id = '\(entry.id)'")

        try await setup.database.deleteAllRecords(at: setup.now)

        #expect(try await setup
            .count("reward_goal WHERE id = '\(goal.id)' AND entry_id IS NULL") == 1)
    }

    @Test
    func deletesOnlyOwnAdjustments() async throws {
        let setup = try await Setup()
        let day = try #require(LocalDate("2026-10-12"))
        try await setup.database.saveAdjustment(-300, of: setup.other, on: day, at: setup.now)
        try await setup.database.saveAdjustment(400, of: setup.shared, on: day, at: setup.now)

        let count = try await setup.database.deletableRecordCount()
        try await setup.database.deleteAllRecords(at: setup.now)

        #expect(count == 1)
        #expect(try await setup.count("adjustment WHERE wallet_id = '\(setup.shared)'") == 1)
        #expect(try await setup.count("adjustment") == 1)
    }

    @Test
    func countsOnlyDeletableRecords() async throws {
        let setup = try await Setup()
        try await setup.addOwnRecords()
        try await setup.addSharedRecords()

        let count = try await setup.database.deletableRecordCount()

        #expect(count == 5)
    }

    @Test
    func countsRecordsWithoutEntries() async throws {
        let setup = try await Setup()
        let day = try #require(LocalDate("2026-10-13"))
        try await setup.database.markNoSpendDay(day, at: setup.now)

        let count = try await setup.database.deletableRecordCount()

        #expect(count == 1)
    }
}

extension RecordResetWriteTests {
    struct Setup {
        let base: SyncTests.Setup
        let shared: Wallet.ID
        let other: Wallet.ID
        let food: EntryCategory.ID
        let now = Date(timeIntervalSince1970: 1_791_000_000)
    }
}

extension RecordResetWriteTests.Setup {
    var database: AppDatabase {
        base.database
    }

    init() async throws {
        let base = try await SyncTests.Setup(enabled: false)
        let shared = try #require(try await Wallet.ID(base.walletID()))
        let other = try #require(try await Wallet.ID(base.otherWalletID()))
        let food = try #require(try await EntryCategory.ID(base.value(
            "SELECT id FROM category WHERE name = '食費'"
        )))

        try await base.database.startSharing(shared)

        self.init(base: base, shared: shared, other: other, food: food)
    }

    func execute(_ sql: String) async throws {
        try await base.execute(sql)
    }

    func count(_ source: String) async throws -> Int {
        let value = try await base.value("SELECT COUNT(*) FROM \(source)")
        return try #require(Int(value))
    }

    func counts(of tables: [String]) async throws -> [Int] {
        var counts: [Int] = []

        for table in tables {
            try await counts.append(count(table))
        }

        return counts
    }

    @discardableResult
    func addOwnRecords() async throws -> Entry {
        let day = try #require(LocalDate("2026-10-12"))
        let noSpend = try #require(LocalDate("2026-10-13"))
        let icon = try #require(try await Icon.ID(base.iconID()))
        let ruleDraft = RewardRuleDraft(
            name: "自炊した日",
            amount: 500,
            icon: IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")
        )

        let rule = try await database.saveRewardRule(ruleDraft, at: now)
        let entry = try await database.saveEntry(draft(wallet: other, on: day), at: now)

        try await database.saveValuation(150_000, of: other, on: day, at: now)
        try await database.setReward(rule.id, isAchieved: true, on: day, at: now)
        try await database.stamp(icon, on: day, at: now)
        try await database.markNoSpendDay(noSpend, at: now)

        return entry
    }

    func addSharedRecords() async throws {
        let day = try #require(LocalDate("2026-10-14"))

        let transfer = EntryDraft(
            type: .transfer,
            amount: 1000,
            date: day,
            categoryId: nil,
            walletId: other,
            toWalletId: shared,
            fee: 110
        )

        try await database.saveEntry(draft(wallet: shared, on: day), at: now)
        try await database.saveEntry(transfer, at: now)
        try await database.saveValuation(80000, of: shared, on: day, at: now)
    }

    func draft(wallet: Wallet.ID, on date: LocalDate) -> EntryDraft {
        EntryDraft(
            type: .expense,
            amount: 500,
            date: date,
            categoryId: food,
            walletId: wallet
        )
    }
}
