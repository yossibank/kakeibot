import Core
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringListModel {
    public private(set) var recurrings: [Recurring] = []
    public private(set) var options: EntryOptions?
    public private(set) var errorMessage: String?

    let today: LocalDate

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        today: LocalDate
    ) {
        self.database = database
        self.today = today
    }
}

public extension RecurringListModel {
    struct Row: Identifiable {
        public let id: Recurring.ID
        public let title: String
        public let detail: String
        public let amount: Int
        public let type: Entry.Kind
        public let icon: Icon?
        public let next: LocalDate?
    }

    var rows: [Row] {
        recurrings.map(row(for:))
    }

    func editModel(for id: Recurring.ID?) -> RecurringEditModel {
        RecurringEditModel(database: database, today: today, editing: id)
    }

    func observe() async {
        do {
            options = try await database.entryOptions()

            for try await recurrings in database.recurringUpdates() {
                self.recurrings = recurrings
                options = try await database.entryOptions()
            }
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }
}

private extension RecurringListModel {
    static let loadFailedMessage = "固定費を読めませんでした"

    func row(for recurring: Recurring) -> Row {
        let categories = (options?.expenseCategories ?? [])
            + (options?.incomeCategories ?? [])

        let category = categories.first { $0.id == recurring.categoryId }
        let wallet = options?.wallets.first { $0.id == recurring.walletId }
        let memo = recurring.memo.flatMap { $0.isEmpty ? nil : $0 }

        let schedule = RecurringText.schedule(
            recurring.frequency,
            month: recurring.month ?? recurring.startDate.month,
            day: recurring.day
        )

        let detail = [schedule, wallet?.name]
            .compactMap(\.self)
            .joined(separator: "・")

        return Row(
            id: recurring.id,
            title: memo ?? category?.name ?? "固定費",
            detail: detail,
            amount: recurring.amount,
            type: recurring.type,
            icon: category.flatMap { options?.icons[$0.iconId] },
            next: recurring.nextDate(onOrAfter: today)
        )
    }
}
