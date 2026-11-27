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

        public internal(set) var outcome = ScreenOutcome<EntryChange>()
        public internal(set) var pendingDay: LocalDate?

        public let errorNotice: ErrorNotice

        init(
            today: LocalDate,
            wait: ScreenWait
        ) {
            self.today = today
            self.errorNotice = ErrorNotice(wait: wait)
        }
    }
}
