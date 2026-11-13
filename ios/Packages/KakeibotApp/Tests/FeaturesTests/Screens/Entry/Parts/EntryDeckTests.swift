import Core
@testable import Features
import Testing

struct EntryDeckTests {
    @Test
    func startsWithTheFirstField() {
        #expect(EntryDeck.start(for: .expense) == .category)
        #expect(EntryDeck.start(for: .income) == .category)
        #expect(EntryDeck.start(for: .transfer) == .transfer)
    }

    @Test
    func pointsWalletsToTheTransferField() {
        let source = EntryDeck.wallet(.source)
        let destination = EntryDeck.wallet(.destination)

        #expect(source.field(for: .expense) == .wallet(.source))
        #expect(source.field(for: .transfer) == .transfer)
        #expect(destination.field(for: .transfer) == .transfer)
    }

    @Test
    func ordersDecksByTheirFields() {
        #expect(EntryDeck.category.order(for: .expense) == 0)
        #expect(EntryDeck.wallet(.source).order(for: .expense) == 1)
        #expect(EntryDeck.date.order(for: .expense) == 2)
        #expect(EntryDeck.amount.order(for: .expense) == 3)
        #expect(EntryDeck.wallet(.destination).order(for: .transfer) == 0)
        #expect(EntryDeck.fee.order(for: .transfer) == 1)
    }
}
