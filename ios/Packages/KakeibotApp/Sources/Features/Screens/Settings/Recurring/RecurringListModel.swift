import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringListModel: ScreenModel {
    public var type: Entry.Kind = .expense
    public var movingOrder: [Recurring.ID]?
    public var errorNotice = ErrorNotice()

    public private(set) var recurrings: [Recurring] = []
    public private(set) var list: EntryList?

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
        public let amount: Int?
        public let type: Entry.Kind
        public let icon: Icon?
        public let next: LocalDate?
        public let closing: String?
    }

    var visible: [Recurring] {
        recurrings(isHidden: false)
    }

    var hidden: [Recurring] {
        recurrings(isHidden: true)
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

    var monthTotal: Int {
        let month = today.yearMonth.period(startingOn: .first)

        guard let list else {
            return visible.total(of: type, in: month)
        }

        return visible.reduce(0) { sum, recurring in
            let dates = recurring.dates(from: month.lowerBound, through: month.upperBound)
            return sum + dates.reduce(0) { $0 + list.amount(of: recurring, on: $1) }
        }
    }

    static func title(of type: Entry.Kind) -> String {
        type == .transfer ? "振替" : "固定費"
    }

    func hintFlag() -> SettingsScreenFlag {
        .closedHint(.recurrings, in: database)
    }

    func hiddenListFlag() -> SettingsScreenFlag {
        .openHiddenList(.recurrings, in: database)
    }

    func editModel(for id: Recurring.ID?) -> RecurringEditModel {
        RecurringEditModel(
            database: database,
            today: today,
            type: type,
            editing: id
        )
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

    func recurrings(isHidden: Bool) -> [Recurring] {
        recurrings.filter { recurring in
            recurring.type == type && (recurring.archivedAt != nil) == isHidden
        }
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
        let title = list.title(of: recurring) ?? Self.title(of: recurring.type)
        let detail = [schedule, holiday].rowDetail ?? schedule
        let place = list.place(of: recurring)
        let next = recurring.nextDate(onOrAfter: today)
        let amount = list.amount(of: recurring, on: next ?? today)
        let icon = list.icon(of: recurring)

        return Row(
            id: recurring.id,
            title: title,
            schedule: detail,
            place: place,
            amount: amount,
            type: recurring.type,
            icon: icon,
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
        let others = recurrings.map(\.id).filter { !ids.contains($0) }
        let ordered = ids + others

        try await database.reorderRecurrings(ordered, at: Date())
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
        try await database.deleteRecurring(id, at: Date())
    }

    public func restoreRemoved(_ deletion: Deletion) async throws {
        try await database.restore(deletion)
    }
}
