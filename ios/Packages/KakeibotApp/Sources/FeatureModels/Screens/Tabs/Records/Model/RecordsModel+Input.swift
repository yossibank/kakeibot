import Core
import Observation
import Store

public extension RecordsModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var today: LocalDate
        public internal(set) var list: Loadable<EntryList> = .loading
        public internal(set) var monthStartDay: MonthStartDay = .first
        public internal(set) var weekStart: Weekday = .sunday
        public internal(set) var noSpendDays: Set<LocalDate> = []
        public internal(set) var stampBook: StampBook?
        public internal(set) var stampShelf: ShelfIconList?
        public internal(set) var rewardBank: RewardBank?
        public internal(set) var recurrings: [Recurring] = []
        public internal(set) var recentSearches: [String] = []
        public internal(set) var layout: RecordsLayout = .calendar

        init(today: LocalDate) {
            self.today = today
        }
    }
}
