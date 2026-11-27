import Core
import DesignSystem
import Observation
import Store

public extension RecordsModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var today: LocalDate
        public var selectedDate: LocalDate?
        public var isSearching = false
        public var searchText = ""
        public var filter = EntryFilter()
        public var outcome = ScreenOutcome<Deletion>()
        public var screen = Screen()
        public var prompt = Shown<Prompt>()

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
        isSearching = false
        searchText = ""
    }

    func clearFilter() {
        filter = EntryFilter()
    }

    func move(months: Int) {
        month = month.adding(months: months)
        selectedDate = nil
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
        selectedDate = date
    }

    func openMonth(_ month: YearMonth) {
        closeSearch()
        self.month = month
        selectedDate = nil
    }

    func setMonth(_ month: YearMonth) {
        self.month = month
    }
}
