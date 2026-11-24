import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringEditModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        today: LocalDate,
        type: Entry.Kind = .expense,
        editing id: Recurring.ID? = nil,
        paying wallet: Wallet.ID? = nil
    ) {
        let state = State(type: type, today: today, isScheduleOpen: id == nil)
        let input = Input(today: today, editingId: id, paidWallet: wallet)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension RecurringEditModel {
    @MainActor
    @Observable
    final class Input: SettingsEditHidingInput {
        public internal(set) var isHidden = false
        public internal(set) var options: EntryOptions?
        public internal(set) var cardBills: [Recurring] = []
        public internal(set) var loanBalances: [Wallet.ID: Int] = [:]
        public internal(set) var authorization: NotificationAuthorization = .allowed

        public let today: LocalDate

        var baseline: RecurringDraft?
        var generatedUntil: LocalDate?

        let editingId: Recurring.ID?
        let paidWallet: Wallet.ID?

        init(
            today: LocalDate,
            editingId: Recurring.ID?,
            paidWallet: Wallet.ID?
        ) {
            self.today = today
            self.editingId = editingId
            self.paidWallet = paidWallet
        }
    }

    static let remindChoices: [Int?] = [nil, 0, 1, 3, 7]
    static let destinationTitle = "振替先"

    func select(_ type: Entry.Kind) {
        guard type != state.type else {
            return
        }

        state.type = type
        state.categoryId = output.categories.first?.id

        presetDestination()
        suggestHolidayShift()
    }

    func select(category id: EntryCategory.ID) {
        state.categoryId = id
        suggestHolidayShift()
    }

    func choose(_ shift: HolidayShift) {
        state.schedule.holidayShift = shift
        state.schedule.isHolidayShiftChosen = true
    }

    func press(_ key: AmountCalculator.Key) {
        state.calculator.press(key)
    }

    func pressFee(_ key: AmountCalculator.Key) {
        state.feeCalculator.press(key)
    }

    func setFee(_ amount: Int) {
        state.feeCalculator = AmountCalculator(amount: amount)
    }

    func refreshAuthorization(_ permission: NotificationPermission) async {
        input.authorization = await permission.authorization()
    }

    func save(permission: NotificationPermission = .allowed) async -> Bool {
        if let text = output.problemMessage {
            state.errorNotice.show(text)
            return false
        }

        do {
            try await dependencies.database.saveRecurring(
                output.draft,
                editing: input.editingId,
                today: input.today,
                at: dependencies.clock.now
            )

            await requestPermissionIfReminding(permission)

            return true
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }
}

extension RecurringEditModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }
}

private extension RecurringEditModel {
    func requestPermissionIfReminding(_ permission: NotificationPermission) async {
        guard state.schedule.remindDaysBefore != nil else {
            return
        }

        await permission.requestIfUndecided()
    }
}

extension RecurringEditModel: SettingsEditGroups, SettingsEditRemoving {
    static let deleteFailedMessage = SettingsEditMessage.saveFailed

    var edited: RecurringDraft {
        output.draft
    }

    var problemMessage: String? {
        output.problemMessage
    }

    func remove(_ id: Recurring.ID) async throws -> Deletion {
        try await dependencies.database.deleteRecurring(id, at: dependencies.clock.now)
    }

    func saveHidden(
        _ id: Recurring.ID,
        isHidden: Bool
    ) async throws {
        try await dependencies.database.setRecurringHidden(
            id,
            isHidden: isHidden,
            today: input.today,
            at: dependencies.clock.now
        )
    }
}
