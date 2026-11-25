import Core
import FeatureModels
import Testing

struct EntryDeckTests {
    @Test
    func startsWithTheFirstField() {
        #expect(EntryModel.Deck.start(for: .expense) == .category)
        #expect(EntryModel.Deck.start(for: .income) == .category)
        #expect(EntryModel.Deck.start(for: .transfer) == .transfer)
    }

    @Test
    func pointsWalletsToTheTransferField() {
        let source = EntryModel.Deck.wallet(.source)
        let destination = EntryModel.Deck.wallet(.destination)

        #expect(source.field(for: .expense) == .wallet(.source))
        #expect(source.field(for: .transfer) == .transfer)
        #expect(destination.field(for: .transfer) == .transfer)
    }

    @Test
    func ordersDecksByTheirFields() {
        #expect(EntryModel.Deck.category.order(for: .expense) == 0)
        #expect(EntryModel.Deck.wallet(.source).order(for: .expense) == 1)
        #expect(EntryModel.Deck.date.order(for: .expense) == 2)
        #expect(EntryModel.Deck.amount.order(for: .expense) == 3)
        #expect(EntryModel.Deck.wallet(.destination).order(for: .transfer) == 0)
        #expect(EntryModel.Deck.fee.order(for: .transfer) == 1)
    }
}
