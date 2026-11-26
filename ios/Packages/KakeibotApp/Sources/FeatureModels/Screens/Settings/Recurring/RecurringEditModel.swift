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

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
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
        self.dependencies = parts
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

        public internal(set) var baseline: RecurringDraft?

        public let editingId: Recurring.ID?

        var generatedUntil: LocalDate?

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
}

public extension RecurringEditModel {
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

    func refreshAuthorization(_ permission: NotificationPermission) async {
        input.authorization = await permission.authorization()
    }

    @discardableResult
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
            await finishSave()

            return true
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
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

extension RecurringEditModel: SettingsEditRemoving {
    public static let deleteFailedMessage = SettingsEditMessage.saveFailed

    public var edited: RecurringDraft {
        output.draft
    }

    public var problemMessage: String? {
        output.problemMessage
    }

    public func remove(_ id: Recurring.ID) async throws -> Deletion {
        try await dependencies.database.deleteRecurring(id, at: dependencies.clock.now)
    }

    public func saveHidden(
        _ id: Recurring.ID,
        isHidden: Bool
    ) async throws {
        try await dependencies.database.setRecurringHidden(
            id,
            isHidden: isHidden,
            today: input.today,
            at: dependencies.clock.now
        )

        input.isHidden = isHidden
    }
}
