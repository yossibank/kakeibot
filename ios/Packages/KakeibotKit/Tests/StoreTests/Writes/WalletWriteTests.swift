import Core
import Foundation
import Store
import Testing

struct WalletWriteTests {
    @Test
    func addsWalletAtTheEnd() async throws {
        let setup = try await Setup()

        let saved = try await setup.database.saveWallet(
            setup.draft,
            at: setup.now
        )
        let list = try await setup.database.entryList()
        let icon = try #require(list.icons[saved.iconId])

        #expect(saved.sortOrder == 2)
        #expect(saved.name == "楽天カード")
        #expect(saved.initialBalance == -38000)
        #expect(icon.text == "楽")
        #expect(list.wallets[saved.id] == saved)
    }

    @Test
    func updatesWalletAndIcon() async throws {
        let setup = try await Setup()
        let later = setup.now.addingTimeInterval(60)
        let bank = try await setup.wallet(named: "銀行")
        var draft = setup.draft
        draft.name = "ゆうちょ"
        draft.kind = .bank
        draft.mark = .emoji("📮")
        draft.initialBalance = 120_000

        let updated = try await setup.database.saveWallet(
            draft,
            editing: bank.id,
            at: later
        )
        let list = try await setup.database.entryList()
        let icon = try #require(list.icons[updated.iconId])

        #expect(updated.id == bank.id)
        #expect(updated.name == "ゆうちょ")
        #expect(updated.initialBalance == 120_000)
        #expect(updated.sortOrder == bank.sortOrder)
        #expect(updated.updatedAt == later)
        #expect(icon.id == bank.iconId)
        #expect(icon.emoji == "📮")
    }

    @Test
    func reordersWallets() async throws {
        let setup = try await Setup()
        let cash = try await setup.wallet(named: "財布")
        let bank = try await setup.wallet(named: "銀行")

        try await setup.database.reorderWallets(
            [bank.id, cash.id],
            at: setup.now
        )
        let options = try await setup.database.entryOptions()

        #expect(options.wallets.map(\.name) == ["銀行", "財布"])
    }

    @Test
    func hidesAndShowsWallet() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")

        try await setup.database.setWalletHidden(
            bank.id,
            isHidden: true,
            at: setup.now
        )
        let hidden = try await setup.database.entryOptions()

        try await setup.database.setWalletHidden(
            bank.id,
            isHidden: false,
            at: setup.now
        )
        let shown = try await setup.database.entryOptions()

        #expect(hidden.wallets.map(\.name) == ["財布"])
        #expect(shown.wallets.map(\.name) == ["財布", "銀行"])
    }

    @Test
    func keepsTheLastShownWallet() async throws {
        let setup = try await Setup()
        let cash = try await setup.wallet(named: "財布")
        let bank = try await setup.wallet(named: "銀行")

        try await setup.database.setWalletHidden(
            bank.id,
            isHidden: true,
            at: setup.now
        )

        await #expect(throws: AppDatabase.WalletWriteError.lastShownWallet) {
            try await setup.database.setWalletHidden(
                cash.id,
                isHidden: true,
                at: setup.now
            )
        }
    }

    @Test
    func deletesWalletWithItsRecurringsAndValuations() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let card = try await setup.database.saveWallet(
            setup.draft,
            at: setup.now
        )

        let day = try #require(LocalDate("2026-11-01"))

        let draft = RecurringDraft(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: bank.id,
            toWalletId: card.id,
            frequency: .monthly,
            month: 1,
            day: 27,
            closingDay: 31,
            startDate: day
        )

        try await setup.database.saveRecurring(draft, today: day, at: setup.now)

        try await setup.database.saveValuation(
            0,
            of: card.id,
            on: day,
            at: setup.now
        )

        try await setup.database.deleteWallet(card.id)
        let list = try await setup.database.entryList()
        let recurrings = try await setup.database.recurrings()

        #expect(list.wallets[card.id] == nil)
        #expect(list.valuations.isEmpty)
        #expect(recurrings.isEmpty)
    }

    @Test
    func keepsWalletWithEntries() async throws {
        let setup = try await Setup()
        let cash = try await setup.wallet(named: "財布")
        let options = try await setup.database.entryOptions()
        let food = try #require(options.expenseCategories.first)
        let day = try #require(LocalDate("2026-11-01"))

        let entry = EntryDraft(
            type: .expense,
            amount: 500,
            date: day,
            categoryId: food.id,
            walletId: cash.id
        )

        try await setup.database.saveEntry(entry, at: setup.now)

        await #expect(throws: AppDatabase.WalletWriteError.hasEntries) {
            try await setup.database.deleteWallet(cash.id)
        }
    }

    @Test
    func rejectsUnknownWallet() async throws {
        let setup = try await Setup()

        await #expect(throws: AppDatabase.WalletWriteError.walletNotFound) {
            try await setup.database.saveWallet(
                setup.draft,
                editing: Wallet.ID(),
                at: setup.now
            )
        }
    }
}

extension WalletWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
        let draft: WalletDraft
    }
}

extension WalletWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)

        let draft = WalletDraft(
            kind: .card,
            name: "楽天カード",
            mark: .text("楽"),
            color: "#BF4040",
            initialBalance: -38000
        )

        self.init(database: database, now: now, draft: draft)
    }

    func wallet(named name: String) async throws -> Wallet {
        let options = try await database.entryOptions()
        return try #require(options.wallets.first { $0.name == name })
    }
}
