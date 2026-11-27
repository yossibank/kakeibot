import Core
import Observation
import Store

public extension EntryModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var today: LocalDate
        public internal(set) var options: EntryOptions?
        public internal(set) var history: EntryList?
        public internal(set) var recentMemos: [String] = []
        public internal(set) var recentItemNames: [String] = []
        public internal(set) var weekStart: Weekday = .sunday
        public internal(set) var receiptSavedCount = 0
        public internal(set) var receiptGuideHidden = false
        public internal(set) var editingId: Entry.ID?

        var allTemplates: [EntryTemplate] = []
        var cardBills: [Recurring] = []
        var budgets: [Budget] = []
        var monthStartDay: MonthStartDay = .first
        var carryoverFrom: YearMonth?
        var original: Entry?
        var originalFee: Entry?
        var baseline: Snapshot?

        let startingTemplate: EntryTemplate?

        init(
            today: LocalDate,
            editingId: Entry.ID?,
            startingTemplate: EntryTemplate?
        ) {
            self.today = today
            self.editingId = editingId
            self.startingTemplate = startingTemplate
        }
    }
}
