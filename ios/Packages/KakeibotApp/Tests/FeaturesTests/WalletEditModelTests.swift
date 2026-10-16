import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct WalletEditModelTests {
    @Test
    func addsCardWithNegativeBalance() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database)
        model.name = "楽天カード"
        model.kind = .card
        model.isNegative = true
        model.inputAmount("0038,000円")

        let saved = try #require(await model.save())
        let list = try await setup.database.entryList()
        let icon = try #require(list.icons[saved.iconId])

        #expect(model.amountText == "38000")
        #expect(model.amountDisplay == "38,000")
        #expect(saved.initialBalance == -38000)
        #expect(saved.kind == .card)
        #expect(icon.glyph == .card)
    }

    @Test
    func keepsChosenGlyphWhenKindChanges() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database)

        model.kind = .bank
        let followed = model.icon.glyph
        model.icon.glyph = .coin
        model.kind = .card

        #expect(followed == .bank)
        #expect(model.icon.glyph == .coin)
    }

    @Test
    func loadsAndEditsWallet() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let model = WalletEditModel(database: setup.database, editing: bank.id)
        await model.load()
        let loaded = model.name
        let isChanged = model.isChanged

        model.name = "ゆうちょ"
        model.inputAmount("120000")
        let saved = try #require(await model.save())

        #expect(loaded == "銀行")
        #expect(!isChanged)
        #expect(saved.id == bank.id)
        #expect(saved.name == "ゆうちょ")
        #expect(saved.initialBalance == 120_000)
    }

    @Test
    func refusesToHideTheLastWallet() async throws {
        let setup = try await Setup()
        let cash = try await setup.wallet(named: "財布")
        let bank = try await setup.wallet(named: "銀行")

        let bankModel = WalletEditModel(
            database: setup.database,
            editing: bank.id
        )
        let hid = await bankModel.setHidden(true)

        let cashModel = WalletEditModel(
            database: setup.database,
            editing: cash.id
        )
        let refused = await cashModel.setHidden(true)

        #expect(hid)
        #expect(!refused)
        #expect(cashModel.errorMessage == "最後の 1 つの財布は非表示にできません")
    }
}

extension WalletEditModelTests {
    struct Setup {
        let database: AppDatabase
    }
}

extension WalletEditModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        self.init(database: database)
    }

    func wallet(named name: String) async throws -> Wallet {
        let options = try await database.entryOptions()
        return try #require(options.wallets.first { $0.name == name })
    }
}
