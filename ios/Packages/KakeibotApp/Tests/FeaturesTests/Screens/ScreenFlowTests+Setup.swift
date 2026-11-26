import Core
import FeatureModels
import Foundation
import Store
import Testing
import TestSupport

extension ScreenFlowTests {
    struct Setup {
        let database: AppDatabase
        let today: LocalDate
        let cash: Wallet.ID
        let bank: Wallet.ID
    }

    @MainActor
    final class Tabs {
        let home: HomeModel
        let records: RecordsModel
        let review: ReviewModel
        let assets: AssetsModel
        let notice: EntryNoticeModel

        private var tasks: [Task<Void, Never>] = []

        init(_ setup: Setup) {
            let parts = ScreenParts(database: setup.database, clock: setup.clock)
            let today = setup.today

            self.home = HomeModel(parts: parts, today: today)
            self.records = RecordsModel(parts: parts, today: today)
            self.review = ReviewModel(parts: parts, today: today)
            self.assets = AssetsModel(parts: parts, today: today)
            self.notice = EntryNoticeModel(parts: parts)
        }
    }
}

extension ScreenFlowTests.Setup {
    var clock: ScreenClock {
        .fixed(Self.noon(of: today))
    }

    init(today text: String = "2026-10-15") async throws {
        let database = try AppDatabase.inMemory()
        let today = try #require(LocalDate(text))

        try database.insertDefaultsIfEmpty(at: Self.noon(of: today))

        let options = try await database.entryOptions()

        self.init(
            database: database,
            today: today,
            cash: options.wallets[0].id,
            bank: options.wallets[1].id
        )
    }

    init(
        sharing database: AppDatabase,
        today: LocalDate
    ) async throws {
        let options = try await database.entryOptions()

        self.init(
            database: database,
            today: today,
            cash: options.wallets[0].id,
            bank: options.wallets[1].id
        )
    }

    static func noon(of date: LocalDate) -> Date {
        date.startOfDay(in: .current).addingTimeInterval(12 * 60 * 60)
    }

    @MainActor
    func openTabs() async -> ScreenFlowTests.Tabs {
        let tabs = ScreenFlowTests.Tabs(self)

        await tabs.open()

        return tabs
    }

    @MainActor
    func entryModel(
        editing id: Entry.ID? = nil,
        type: Entry.Kind = .expense
    ) async -> EntryModel {
        let model = EntryModel(
            parts: ScreenParts(database: database, clock: clock),
            editing: id,
            date: today,
            type: type
        )

        await model.load()

        return model
    }

    @MainActor
    func record(
        _ amount: Int,
        type: Entry.Kind = .expense,
        on date: LocalDate? = nil,
        wallet: Wallet.ID? = nil,
        memo: String = ""
    ) async throws -> EntryChange {
        let model = await entryModel(type: type)

        model.type(amount)

        if let wallet {
            model.setWallet(wallet)
        }

        model.state.setDate(date ?? today)
        model.state.memo = memo

        return try #require(await model.save())
    }

    @MainActor
    func passDay(
        to date: LocalDate,
        in tabs: ScreenFlowTests.Tabs
    ) async throws {
        try await database.generateRecurringEntries(through: date, at: Self.noon(of: date))

        tabs.setToday(date)
    }

    func saveCard() async throws -> Wallet {
        let wallet = WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#4A6FA5",
            initialBalance: 0
        )

        let card = try await database.save(wallet, at: Self.noon(of: today))

        let bill = RecurringDraft(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: bank,
            toWalletId: card.id,
            frequency: .monthly,
            month: 1,
            day: 27,
            closingDay: 31,
            startDate: today
        )

        _ = try await database.saveRecurring(bill, today: today, at: Self.noon(of: today))

        return card
    }
}

extension ScreenFlowTests.Tabs {
    var lists: [EntryList?] {
        [
            home.input.list.value,
            records.input.list.value,
            review.input.list.value,
            assets.output.list
        ]
    }

    var entryIDs: [[Entry.ID]] {
        lists.map { $0?.entries.map(\.id) ?? [] }
    }

    var amounts: [[Int]] {
        lists.map { $0?.entries.map(\.amount) ?? [] }
    }

    func open() async {
        tasks = [
            Task { await home.run() },
            Task { await records.run() },
            Task { await review.run() },
            Task { await assets.run() }
        ]

        await ObservationWait.until {
            self.home.input.list.isLoaded
                && self.records.input.list.isLoaded
                && self.review.input.list.isLoaded
                && self.assets.output.list != nil
        }
    }

    func close() {
        for task in tasks {
            task.cancel()
        }

        tasks = []
    }

    func setToday(_ today: LocalDate) {
        home.state.today = today
        records.state.today = today
        review.state.today = today
        assets.setToday(today)
    }

    func wait(
        sourceLocation: SourceLocation = #_sourceLocation,
        _ isReady: @escaping @MainActor (ScreenFlowTests.Tabs) -> Bool
    ) async {
        await ObservationWait.until(sourceLocation: sourceLocation) {
            isReady(self)
        }
    }

    func balance(of wallet: Wallet.ID) -> Int? {
        assets.output.rows.first { $0.wallet.id == wallet }?.balance
    }
}

extension EntryModel {
    func type(_ amount: Int) {
        for key in AmountCalculator.Key.digits(of: amount) {
            state.press(key)
        }
    }
}

extension AmountCalculator.Key {
    static func digits(of amount: Int) -> [AmountCalculator.Key] {
        String(amount).compactMap(\.wholeNumberValue).map(AmountCalculator.Key.digit)
    }
}
