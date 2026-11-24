import Core
import DesignSystem
import Observation

public extension HomeModel {
    @MainActor
    @Observable
    final class State {
        public var today: LocalDate
        public var templateType: Entry.Kind = .expense
        public var billPage = 0

        public internal(set) var errorNotice = ErrorNotice()

        init(today: LocalDate) {
            self.today = today
        }
    }
}
