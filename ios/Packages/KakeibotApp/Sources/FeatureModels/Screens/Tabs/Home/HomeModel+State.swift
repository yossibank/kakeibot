import Core
import DesignSystem
import Observation

public extension HomeModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var today: LocalDate
        public var templateType: Entry.Kind = .expense
        public var billPage = 0
        public var openRowId: Entry.ID?
        public var openStamp: StampBook.Tally?
        public var shelf = Shelf()
        public var customized: SetupItem?
        public var errorNotice = ErrorNotice()

        public internal(set) var outcome = ScreenOutcome<EntryChange>()
        public internal(set) var pendingDay: LocalDate?

        init(today: LocalDate) {
            self.today = today
        }
    }
}
