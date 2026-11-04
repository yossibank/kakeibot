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

    @Test
    func sortsSameDayByCategoryOrder() throws {
        let now = Date()
        let later = now.addingTimeInterval(1)
        let latest = now.addingTimeInterval(2)
        let date = try #require(LocalDate(year: 2026, month: 11, day: 4))
        let food = Self.category(.expense, sortOrder: 1, at: now)
        let rent = Self.category(.expense, sortOrder: 0, at: now)
        let salary = Self.category(.income, sortOrder: 0, at: now)
        let categories = Dictionary(uniqueKeysWithValues: [food, rent, salary].map { ($0.id, $0) })
        let transfer = Self.entry(.transfer, category: nil, on: date, at: latest)
        let income = Self.entry(.income, category: salary.id, on: date, at: latest)
        let older = Self.entry(.expense, category: food.id, on: date, at: now)
        let newer = Self.entry(.expense, category: food.id, on: date, at: later)
        let first = Self.entry(.expense, category: rent.id, on: date, at: now)
        let entries = [transfer, income, older, newer, first]

        let days = EntryDay.grouping(entries, categories: categories)

        let ids = days.first?.entries.map(\.id)
        #expect(ids == [first.id, newer.id, older.id, income.id, transfer.id])
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
            try CoreFixture.cases("entry/entry-day.json")
        }
    }

    static func category(
        _ kind: EntryCategory.Kind,
        sortOrder: Int,
        at date: Date
    ) -> EntryCategory {
        EntryCategory(
            kind: kind,
            name: "\(kind)\(sortOrder)",
            iconId: Icon.ID(),
            sortOrder: sortOrder,
            createdAt: date,
            updatedAt: date
        )
    }

    static func entry(
        _ type: Entry.Kind,
        category: EntryCategory.ID?,
        on date: LocalDate,
        at createdAt: Date
    ) -> Entry {
        Entry(
            type: type,
            amount: 100,
            date: date,
            categoryId: category,
            walletId: Wallet.ID(),
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}
