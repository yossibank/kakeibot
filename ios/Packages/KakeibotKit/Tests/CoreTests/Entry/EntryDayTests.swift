import Core
import Foundation
import Testing

struct EntryDayTests {
    @Test(arguments: try dayCases)
    func groupsEntriesByDay(fixture: DayCase) {
        let entries = fixture.entries.map(\.entry)

        let days = EntryDay.grouping(entries)
        let summaries = days.map(DaySummary.init)

        #expect(summaries == fixture.days)
    }
}

extension EntryDayTests {
    struct DayCase: Decodable, Sendable {
        let entries: [EntryItem]
        let days: [DaySummary]
    }

    struct EntryItem: Decodable, Sendable {
        let id: Entry.ID
        let type: Entry.Kind
        let amount: Int
        let date: LocalDate
        let createdAt: Date
    }

    struct DaySummary: Decodable, Equatable, Sendable {
        let date: LocalDate
        let expense: Int
        let income: Int
        let entryIds: [Entry.ID]
    }
}

extension EntryDayTests.EntryItem {
    var entry: Entry {
        Entry(
            id: id,
            type: type,
            amount: amount,
            date: date,
            categoryId: nil,
            walletId: Wallet.ID(),
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}

extension EntryDayTests.DaySummary {
    init(_ day: EntryDay) {
        self.init(
            date: day.date,
            expense: day.expenseTotal,
            income: day.incomeTotal,
            entryIds: day.entries.map(\.id)
        )
    }
}

private extension EntryDayTests {
    static var dayCases: [DayCase] {
        get throws {
            try Fixture.load("entry/entry-day.json")
        }
    }
}
