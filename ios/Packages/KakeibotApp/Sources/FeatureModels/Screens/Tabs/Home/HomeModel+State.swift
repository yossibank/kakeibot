import Core
import DesignSystem
import Observation

public extension HomeModel {
    struct Fields: ScreenEditable {
        public var templateType: Entry.Kind = .expense
        public var billPage = 0
        public var shelfQuery = ""
    }

    struct Presented: ScreenEditable {
        public var stamp = Shown<StampBook.Tally>()
        public var shelf = Shown<ShelfPage>()
        public var row = Shown<Entry.ID>()
        public var glow = Shown<SetupItem>()

        public internal(set) var customized: SetupItem?
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var fields = Fields()
        public var presented = Presented()

        public let notices: Notices

        public internal(set) var outcome = ScreenOutcome<EntryChange>()
        public internal(set) var pendingDay = PendingDay()

        init(wait: ScreenWait) {
            self.notices = Notices(wait: wait)
        }
    }
}
