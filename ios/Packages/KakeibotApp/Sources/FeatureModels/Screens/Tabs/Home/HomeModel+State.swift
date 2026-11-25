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

        public var errorNotice = ErrorNotice()

        public internal(set) var outcome = ScreenOutcome<EntryChange>()

        init(today: LocalDate) {
            self.today = today
        }
    }
}
