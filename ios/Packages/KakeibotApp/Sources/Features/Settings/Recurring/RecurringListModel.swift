import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringListModel {
    public private(set) var recurrings: [Recurring] = []
    public private(set) var movingOrder: [Recurring.ID]?
    public private(set) var options: EntryOptions?

    public internal(set) var errorNotice = ErrorNotice()

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

    struct MonthTotal: Equatable {
        public let expense: Int
        public let income: Int
    }

    var rows: [Row] {
        shown.map(row(for:))
    }

    var monthTotal: MonthTotal {
        let month = today.yearMonth.period(startingOn: .first)

        return MonthTotal(
            expense: recurrings.total(of: .expense, in: month),
            income: recurrings.total(of: .income, in: month)
        )
    }

    func move(
        _ id: Recurring.ID,
        to index: Int
    ) {
        var order = movingOrder ?? recurrings.map(\.id)

        guard let from = order.firstIndex(of: id) else {
            return
        }

        let to = min(max(index, 0), order.count - 1)

        guard from != to else {
            return
        }

        order.remove(at: from)
        order.insert(id, at: to)
        movingOrder = order
    }

    func delete(_ id: Recurring.ID) async {
        do {
            try await database.deleteRecurring(id)
        } catch {
            errorNotice.show(Self.deleteFailedMessage)
        }
    }

    func finishMoving() async {
        guard let movingOrder else {
            return
        }

        do {
            try await database.reorderRecurrings(movingOrder, at: Date())
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }

        self.movingOrder = nil
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
            errorNotice.show(Self.loadFailedMessage)
        }
    }
}

private extension RecurringListModel {
    static let loadFailedMessage = "固定費を読めませんでした"
    static let saveFailedMessage = "並びを保存できませんでした"
    static let deleteFailedMessage = "固定費を消せませんでした"

    var shown: [Recurring] {
        guard let movingOrder else {
            return recurrings
        }

        return movingOrder.compactMap { id in
            recurrings.first { $0.id == id }
        }
    }

    static func title(of type: Entry.Kind) -> String {
        type == .transfer ? "振替" : "固定費"
    }

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

        let destination = options?.wallets
            .first { $0.id == recurring.toWalletId }

        let route = [wallet?.name, destination?.name]
            .compactMap(\.self)
            .joined(separator: " → ")

        let place = recurring.type == .transfer ? route : wallet?.name

        let detail = [schedule, place]
            .compactMap(\.self)
            .joined(separator: "・")

        let iconId = recurring.type == .transfer
            ? wallet?.iconId
            : category?.iconId

        return Row(
            id: recurring.id,
            title: memo ?? category?.name ?? Self.title(of: recurring.type),
            detail: detail,
            amount: recurring.amount,
            type: recurring.type,
            icon: iconId.flatMap { options?.icons[$0] },
            next: recurring.nextDate(onOrAfter: today)
        )
    }
}
