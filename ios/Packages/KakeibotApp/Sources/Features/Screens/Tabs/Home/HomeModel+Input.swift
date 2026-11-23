import Core
import Observation
import Store

public extension HomeModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var list: EntryList?
        public internal(set) var isListFailed = false
        public internal(set) var templateOrder: TemplateOrder = .manual
        public internal(set) var syncStatus = SyncStatus.off

        var allTemplates: [EntryTemplate] = []
        var budgets: [Budget] = []
        var recurrings: [Recurring] = []
        var monthStartDay: MonthStartDay = .first
        var carryoverFrom: YearMonth?
        var homeSections = HomeSection.standard
        var homeHiddenSections: Set<HomeSection> = []
        var stampBook: StampBook?
    }
}
