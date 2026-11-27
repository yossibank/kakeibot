import Core
import DesignSystem
import Observation
import Store

public extension RecordsModel {
    struct Fields: ScreenEditable {
        public var selectedDate: LocalDate?
        public var isSearching = false
        public var searchText = ""
        public var filter = EntryFilter()
        public var filterTab: FilterTab = .expense
        public var selection: Set<Entry.ID>?
    }

    struct Presented: ScreenEditable {
        public var panel = Shown<Panel>()
        public var prompt = Shown<Prompt>()
        public var adding = Shown<Adding>()

        public internal(set) var openItemIds: Set<Entry.ID> = []
        public internal(set) var pendingDeleteIDs: [Entry.ID] = []
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice
        public let clearedSearches: UndoNotice<[String]>

        init(wait: ScreenWait) {
            let undoWait = wait.lasting(RecordsModel.clearedSearchesDuration)

            self.error = ErrorNotice(wait: wait)
            self.clearedSearches = UndoNotice(wait: undoWait)
        }
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var fields = Fields()
        public var presented = Presented()

        public let notices: Notices

        public internal(set) var outcome = ScreenOutcome<Deletion>()
        public internal(set) var cursor: MonthCursor

        init(
            month: YearMonth,
            wait: ScreenWait
        ) {
            self.notices = Notices(wait: wait)
            self.cursor = MonthCursor(month: month)
        }
    }
}

public extension RecordsModel.State {
    func closeSearch() {
        fields.isSearching = false
        fields.searchText = ""
    }

    func clearFilter() {
        fields.filter = EntryFilter()
    }

    func move(months: Int) {
        cursor.move(by: months)
        fields.selectedDate = nil
    }

    func requestDelete(
        _ ids: [Entry.ID],
        delete: ([Entry.ID]) -> Void
    ) {
        guard ids.count >= RecordsModel.confirmDeleteThreshold else {
            delete(ids)
            return
        }

        presented.pendingDeleteIDs = ids
        presented.prompt.show(.delete)
    }

    func confirmDelete(delete: ([Entry.ID]) -> Void) {
        let ids = presented.pendingDeleteIDs
        cancelDelete()
        delete(ids)
    }

    func cancelDelete() {
        presented.pendingDeleteIDs = []
        presented.prompt.close(.delete)
    }
}

extension RecordsModel.State {
    func open(
        _ date: LocalDate,
        in month: YearMonth
    ) {
        closeSearch()
        cursor.show(month)
        fields.selectedDate = date
    }

    func openMonth(_ month: YearMonth) {
        closeSearch()
        cursor.show(month)
        fields.selectedDate = nil
    }

    func setMonth(_ month: YearMonth) {
        cursor.show(month)
    }
}
