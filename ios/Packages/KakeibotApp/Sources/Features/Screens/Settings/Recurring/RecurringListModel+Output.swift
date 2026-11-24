import Core
import DesignSystem
import Store

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

    @MainActor
    final class Output: SettingsBoardOutput {
        let input: Input
        let state: State

        public var rows: [Row] {
            shown.compactMap { row(for: $0) }
        }

        public var hiddenRows: [Row] {
            hidden.compactMap { row(for: $0) }
        }

        public var monthTotal: Int {
            let startDay = input.monthStartDay
            let period = input.today.periodMonth(startingOn: startDay).period(startingOn: startDay)

            guard let list = input.list else {
                return visible.total(of: state.type, in: period)
            }

            return visible.total(of: state.type, in: period, entries: list.entries)
        }

        var items: [Recurring] {
            guard input.list != nil, let snapshot = input.snapshot else {
                return []
            }

            return snapshot.filter { $0.type == state.type }
        }

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }

        public func row(for recurring: Recurring) -> Row? {
            input.list.map { row(for: recurring, in: $0) }
        }

        func isHidden(_ item: Recurring) -> Bool {
            item.archivedAt != nil
        }
    }
}

private extension RecurringListModel.Output {
    func row(
        for recurring: Recurring,
        in list: EntryList
    ) -> RecurringListModel.Row {
        let schedule = RecurringText.schedule(
            recurring.frequency,
            month: recurring.month ?? recurring.startDate.month,
            day: recurring.day
        )

        let today = input.today
        let holiday = RecurringText.holidayNote(recurring.holidayShift)
        let closing = recurring.closingDay.map(RecurringText.closingNote)
        let title = list.title(of: recurring) ?? RecurringListModel.title(of: recurring.type)
        let detail = [schedule, holiday].rowDetail ?? schedule
        let place = list.place(of: recurring)
        let next = recurring.nextDate(onOrAfter: today)
        let amount = list.amount(of: recurring, on: next ?? today)
        let icon = list.icon(of: recurring)

        return RecurringListModel.Row(
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
