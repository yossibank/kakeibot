import Core
import Foundation
import Testing

struct EntryDayTests {
    @Test(arguments: try dayCases)
    func groupsEntriesByDay(fixture: DayCase) {
        let entries = fixture.entries.map(\.entry)
        let categories = fixture.categoryMap
        let days = EntryDay.grouping(entries, categories: categories)
        let summaries = days.map(DaySummary.init)
        #expect(summaries == fixture.days)
    }
}

extension EntryDayTests {
    struct DayCase: Decodable, Sendable {
        let categories: [CategoryItem]?
        let entries: [EntryItem]
        let days: [DaySummary]
    }

    struct CategoryItem: Decodable, Sendable {
        let id: EntryCategory.ID
        let kind: EntryCategory.Kind
        let sortOrder: Int
    }

    struct EntryItem: Decodable, Sendable {
        let id: Entry.ID
        let type: Entry.Kind
        let amount: Int
        let date: LocalDate
        let categoryId: EntryCategory.ID?
        let createdAt: Date
    }

    struct DaySummary: Decodable, Equatable, Sendable {
        let date: LocalDate
        let expense: Int
        let income: Int
        let entryIds: [Entry.ID]
    }
}

extension EntryDayTests.DayCase {
    var categoryMap: [EntryCategory.ID: EntryCategory] {
        let pairs = (categories ?? []).map { ($0.id, $0.category) }
        return Dictionary(uniqueKeysWithValues: pairs)
    }
}

extension EntryDayTests.CategoryItem {
    var category: EntryCategory {
        let date = Date(timeIntervalSince1970: 0)

        return EntryCategory(
            id: id,
            kind: kind,
            name: "",
            iconId: Icon.ID(),
            sortOrder: sortOrder,
            createdAt: date,
            updatedAt: date
        )
    }
}

extension EntryDayTests.EntryItem {
    var entry: Entry {
        Entry(
            id: id,
            type: type,
            amount: amount,
            date: date,
            categoryId: categoryId,
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
            try CoreFixture.cases("entry/entry-day.json")
        }
    }
}
