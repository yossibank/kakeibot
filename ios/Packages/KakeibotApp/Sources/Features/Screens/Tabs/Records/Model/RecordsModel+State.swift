import Core
import DesignSystem
import Observation
import Store

public extension RecordsModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public internal(set) var errorNotice = ErrorNotice()

        public var today: LocalDate
        public var selectedDate: LocalDate?
        public var isSearching = false
        public var isConfirmingDelete = false
        public var searchText = ""
        public var filter = EntryFilter()

        public private(set) var month: YearMonth
        public private(set) var layout: RecordsLayout = .calendar
        public private(set) var pendingDeleteIDs: [Entry.ID] = []

        init(today: LocalDate) {
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

    func setLayout(_ layout: RecordsLayout) {
        self.layout = layout
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
        isConfirmingDelete = true
    }

    func confirmDelete(delete: ([Entry.ID]) -> Void) {
        let ids = pendingDeleteIDs
        cancelDelete()
        delete(ids)
    }

    func cancelDelete() {
        pendingDeleteIDs = []
        isConfirmingDelete = false
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
        layout = .calendar
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
