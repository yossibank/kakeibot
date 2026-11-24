import Core
import Observation
import Store

public extension EntryModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var options: EntryOptions?
        public internal(set) var history: EntryList?
        public internal(set) var balances: [Wallet.ID: Int] = [:]
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
        var isSaving = false

        let startingTemplate: EntryTemplate?
        let clock: ScreenClock

        init(
            editingId: Entry.ID?,
            startingTemplate: EntryTemplate?,
            clock: ScreenClock
        ) {
            self.editingId = editingId
            self.startingTemplate = startingTemplate
            self.clock = clock
        }
    }
}

extension EntryModel.Input {
    var today: LocalDate {
        clock.today
    }
}
