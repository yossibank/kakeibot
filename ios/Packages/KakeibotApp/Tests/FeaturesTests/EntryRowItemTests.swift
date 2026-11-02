import Core
@testable import Features
import Foundation
import Store
import Testing

struct EntryRowItemTests {
    @Test
    func showsBillDateOfMovedUsage() throws {
        let setup = try Setup()
        let entry = try setup.entry(billMonth: "2027-02")
        let list = setup.list([setup.bill])
        let item = EntryRowItem(entry, in: list)
        #expect(item.detail == "カード（3/1払い）")
    }

    @Test
    func keepsMonthWhenBillIsUnknown() throws {
        let setup = try Setup()
        let entry = try setup.entry(billMonth: "2030-02")
        let list = setup.list([setup.bill])
        let item = EntryRowItem(entry, in: list)
        #expect(item.detail == "カード（2月払い）")
    }

    @Test
    func skipsHiddenBillOfSameCard() throws {
        let setup = try Setup()
        let hidden = setup.another(day: 20, archived: true)
        let entry = try setup.entry(billMonth: "2027-02")
        let list = setup.list([hidden, setup.bill])
        let item = EntryRowItem(entry, in: list)
        #expect(item.detail == "カード（3/1払い）")
    }

    @Test
    func keepsMonthWhenTwoBillsFit() throws {
        let setup = try Setup()
        let other = setup.another(day: 20, archived: false)
        let entry = try setup.entry(billMonth: "2027-02")
        let list = setup.list([other, setup.bill])
        let item = EntryRowItem(entry, in: list)
        #expect(item.detail == "カード（2月払い）")
    }

    @Test
    func keepsTaxModeOfEntry() throws {
        let setup = try Setup()
        var entry = try setup.entry(billMonth: "2027-02")
        let list = setup.list([setup.bill])
        let exclusive = EntryRowItem(entry, in: list)

        entry.taxIncluded = true

        let included = EntryRowItem(entry, in: list)

        #expect(!exclusive.taxIncluded)
        #expect(included.taxIncluded)
    }
}

extension EntryRowItemTests {
    struct Setup {
        let card: Wallet
        let bill: Recurring

        init() throws {
            let now = Date(timeIntervalSince1970: 1_791_000_000)
            let startDate = try #require(LocalDate("2026-01-01"))

            let card = Wallet(
                name: "カード",
                kind: .card,
                iconId: Icon.ID(),
                initialBalance: 0,
                sortOrder: 0,
                createdAt: now,
                updatedAt: now
            )

            let bill = Recurring(
                type: .transfer,
                amount: 0,
                categoryId: nil,
                walletId: Wallet.ID(),
                toWalletId: card.id,
                frequency: .monthly,
                day: 27,
                holidayShift: .next,
                closingDay: 31,
                startDate: startDate,
                createdAt: now,
                updatedAt: now
            )

            self.card = card
            self.bill = bill
        }
    }
}

extension EntryRowItemTests.Setup {
    func another(
        day: Int,
        archived: Bool
    ) -> Recurring {
        Recurring(
            type: bill.type,
            amount: bill.amount,
            categoryId: nil,
            walletId: bill.walletId,
            toWalletId: bill.toWalletId,
            frequency: bill.frequency,
            day: day,
            holidayShift: bill.holidayShift,
            closingDay: bill.closingDay,
            startDate: bill.startDate,
            archivedAt: archived ? bill.createdAt : nil,
            createdAt: bill.createdAt,
            updatedAt: bill.updatedAt
        )
    }

    func list(_ bills: [Recurring]) -> EntryList {
        EntryList(
            days: [],
            categories: [:],
            tags: [:],
            wallets: [card.id: card],
            icons: [:],
            cardBills: bills
        )
    }

    func entry(billMonth: String) throws -> Entry {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let date = try #require(LocalDate("2027-01-20"))
        let month = YearMonth(billMonth)

        return Entry(
            type: .expense,
            amount: 500,
            date: date,
            categoryId: EntryCategory.ID(),
            walletId: card.id,
            billMonth: month,
            createdAt: now,
            updatedAt: now
        )
    }
}
