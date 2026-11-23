import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringListModel {
    public var type: Entry.Kind = .expense
    public var movingOrder: [Recurring.ID]?
    public var errorNotice = ErrorNotice()

    public internal(set) var snapshot: [Recurring]?

    public private(set) var list: EntryList?
    public private(set) var monthStartDay: MonthStartDay = .first

    let today: LocalDate
    let database: AppDatabase

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

    var rows: [Row] {
        shown.compactMap { row(for: $0) }
    }

    var hiddenRows: [Row] {
        hidden.compactMap { row(for: $0) }
    }

    var monthTotal: Int {
        let period = today
            .periodMonth(startingOn: monthStartDay)
            .period(startingOn: monthStartDay)

        guard let list else {
            return visible.total(of: type, in: period)
        }

        return visible.total(of: type, in: period, entries: list.entries)
    }

    static func title(of type: Entry.Kind) -> String {
        type == .transfer ? "振替" : "固定費"
    }

    func row(for recurring: Recurring) -> Row? {
        list.map { row(for: recurring, in: $0) }
    }

    func observe() async {
        await observeAll([
            {
                await self.observe(self.updates(), into: \.snapshot)
            },
            {
                await self.observe(self.database.entryListUpdates(), into: \.list)
            },
            {
                await self.observe(
                    self.database.settingUpdates(.monthStartDay),
                    into: \.monthStartDay
                )
            }
        ])
    }
}

extension RecurringListModel: SettingsBoardListModel {
    typealias Item = Recurring

    static let loadFailedMessage = "固定費を読めませんでした"

    func read() async throws -> [Recurring] {
        try await database.recurrings(includingHidden: true)
    }

    func updates() -> some AsyncSequence<[Recurring], any Error> {
        database.recurringUpdates(includingHidden: true)
    }

    func items(in snapshot: [Recurring]) -> [Recurring] {
        guard list != nil else {
            return []
        }

        return snapshot.filter { $0.type == type }
    }

    func isHidden(_ item: Recurring) -> Bool {
        item.archivedAt != nil
    }
}

private extension RecurringListModel {
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
    public func saveOrder(_ ids: [Recurring.ID]) async throws {
        let others = (snapshot ?? []).map(\.id).filter { !ids.contains($0) }
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
