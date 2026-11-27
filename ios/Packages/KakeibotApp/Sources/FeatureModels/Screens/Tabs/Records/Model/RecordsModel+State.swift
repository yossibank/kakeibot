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
        public var isAddingMark = false
        public var filterTab: FilterTab = .expense
        public var clearedSearches: [String]?
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var fields = Fields()
        public var presented = Shown<Presented>()
        public var prompt = Shown<Prompt>()

        public internal(set) var today: LocalDate
        public internal(set) var outcome = ScreenOutcome<Deletion>()
        public internal(set) var screen = Screen()

        public private(set) var month: YearMonth
        public private(set) var pendingDeleteIDs: [Entry.ID] = []

        public let errorNotice: ErrorNotice

        init(
            today: LocalDate,
            wait: ScreenWait
        ) {
            self.errorNotice = ErrorNotice(wait: wait)
            self.today = today
            self.month = today.yearMonth
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
        month = month.adding(months: months)
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

        pendingDeleteIDs = ids
        prompt.show(.delete)
    }

    func confirmDelete(delete: ([Entry.ID]) -> Void) {
        let ids = pendingDeleteIDs
        cancelDelete()
        delete(ids)
    }

    func cancelDelete() {
        pendingDeleteIDs = []
        prompt.close(.delete)
    }
}

extension RecordsModel.State {
    func open(
        _ date: LocalDate,
        in month: YearMonth
    ) {
        closeSearch()
        self.month = month
        fields.selectedDate = date
    }

    func openMonth(_ month: YearMonth) {
        closeSearch()
        self.month = month
        fields.selectedDate = nil
    }

    func setMonth(_ month: YearMonth) {
        self.month = month
    }
}
