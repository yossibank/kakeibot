import Core
import DesignSystem
import Observation

public extension HomeModel {
    struct Fields: ScreenEditable {
        public var templateType: Entry.Kind = .expense
        public var billPage = 0
        public var openRowId: Entry.ID?
        public var shelf = Shelf()
        public var customized: SetupItem?
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var fields = Fields()
        public var presented = Shown<StampBook.Tally>()

        public internal(set) var today: LocalDate
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
