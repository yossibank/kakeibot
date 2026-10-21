import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringListModel: ScreenModel {
    public private(set) var recurrings: [Recurring] = []
    public var movingOrder: [Recurring.ID]?
    public private(set) var list: EntryList?

    public var errorNotice = ErrorNotice()

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
        public let schedule: String
        public let place: String?
        public let amount: Int
        public let type: Entry.Kind
        public let icon: Icon?
        public let next: LocalDate?
        public let closing: String?
    }

    struct MonthTotal: Equatable {
        public let expense: Int
        public let income: Int
    }

    var visible: [Recurring] {
        recurrings.filter { $0.archivedAt == nil }
    }

    var hidden: [Recurring] {
        recurrings.filter { $0.archivedAt != nil }
    }

    var rows: [Row] {
        guard let list else {
            return []
        }

        return shown.map { row(for: $0, in: list) }
    }

    var hiddenRows: [Row] {
        guard let list else {
            return []
        }

        return hidden.map { row(for: $0, in: list) }
    }

    var monthTotal: MonthTotal {
        let month = today.yearMonth.period(startingOn: .first)

        return MonthTotal(
            expense: visible.total(of: .expense, in: month),
            income: visible.total(of: .income, in: month)
        )
    }

    func hintFlag() -> SettingsScreenFlag {
        .closedHint(.recurrings, in: database)
    }

    func hiddenListFlag() -> SettingsScreenFlag {
        .openHiddenList(.recurrings, in: database)
    }

    func editModel(for id: Recurring.ID?) -> RecurringEditModel {
        RecurringEditModel(database: database, today: today, editing: id)
    }

    func observe() async {
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observeRecurrings()
            }

            group.addTask {
                await self.observeList()
            }
        }
    }
}

private extension RecurringListModel {
    static let loadFailedMessage = "固定費を読めませんでした"

    static func title(of type: Entry.Kind) -> String {
        type == .transfer ? "振替" : "固定費"
    }

    func observeRecurrings() async {
        await observe(
            database.recurringUpdates(includingHidden: true),
            failure: Self.loadFailedMessage
        ) { recurrings in
            self.recurrings = recurrings
        }
    }

    func observeList() async {
        await observe(
            database.entryListUpdates(),
            failure: Self.loadFailedMessage
        ) { list in
            self.list = list
        }
    }

    func row(
        for recurring: Recurring,
        in list: EntryList
    ) -> Row {
        let schedule = RecurringText.schedule(
            recurring.frequency,
            month: recurring.month ?? recurring.startDate.month,
            day: recurring.day
        )

        let holiday = RecurringText.holidayNote(recurring.holidayShift)
        let closing = recurring.closingDay.map(RecurringText.closingNote)
        let place = list.place(of: recurring)
        let next = recurring.nextDate(onOrAfter: today)

        return Row(
            id: recurring.id,
            title: list.title(of: recurring) ?? Self.title(of: recurring.type),
            schedule: [schedule, holiday].rowDetail ?? schedule,
            place: place,
            amount: list.amount(of: recurring, on: next ?? today),
            type: recurring.type,
            icon: list.icon(of: recurring),
            next: next,
            closing: closing
        )
    }
}

extension RecurringListModel: SettingsBoardModel {
    public func reload() async {
        do {
            recurrings = try await database.recurrings(includingHidden: true)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    public func saveOrder(_ ids: [Recurring.ID]) async throws {
        let ids = ids + hidden.map(\.id)
        try await database.reorderRecurrings(ids, at: Date())
    }

    public func saveHidden(
        _ id: Recurring.ID,
        isHidden: Bool
    ) async throws {
        try await database.setRecurringHidden(
            id,
            isHidden: isHidden,
            today: today,
            at: Date()
        )
    }

    public func remove(_ id: Recurring.ID) async throws -> Deletion {
        try await database.deleteRecurring(id)
    }

    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await database.restore(deletion)
    }
}
