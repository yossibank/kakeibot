import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class RecurringEditModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output
    public let flow: EditFlow<Void>

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        today: LocalDate,
        type: Entry.Kind = .expense,
        editing id: Recurring.ID? = nil,
        paying wallet: Wallet.ID? = nil
    ) {
        let state = State(
            type: type,
            today: today,
            isScheduleOpen: id == nil,
            wait: parts.wait
        )

        let input = Input(today: today, editingId: id, paidWallet: wallet)

        let output = Output(input: input, state: state)
        let source = Source(state: state, input: input, output: output, parts: parts)

        self.state = state
        self.input = input
        self.output = output
        self.flow = EditFlow(source: source)
        self.dependencies = parts
    }
}

public extension RecurringEditModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var options: EntryOptions?
        public internal(set) var cardBills: [Recurring] = []
        public internal(set) var loanBalances: [Wallet.ID: Int] = [:]
        public internal(set) var authorization: NotificationAuthorization = .allowed
        public internal(set) var baseline: RecurringDraft?
        public internal(set) var isHidden = false

        public let today: LocalDate
        public let editingId: Recurring.ID?

        var generatedUntil: LocalDate?

        @ObservationIgnored var permission = NotificationPermission.allowed

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

extension RecurringEditModel {
    @MainActor
    struct Source {
        let state: State
        let input: Input
        let output: Output
        let dependencies: ScreenParts

        init(
            state: State,
            input: Input,
            output: Output,
            parts: ScreenParts
        ) {
            self.state = state
            self.input = input
            self.output = output
            self.dependencies = parts
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
        state.fields.categoryId = output.categories.first?.id
        presetDestination()
        suggestHolidayShift()
    }

    func select(category id: EntryCategory.ID) {
        state.fields.categoryId = id
        suggestHolidayShift()
    }

    func refreshAuthorization(_ permission: NotificationPermission) async {
        input.permission = permission
        input.authorization = await permission.authorization()
    }

    @discardableResult
    func save() async -> Void? {
        await save(permission: input.permission)
    }

    @discardableResult
    func save(permission: NotificationPermission) async -> Void? {
        await source.save(permission: permission)
    }
}

extension RecurringEditModel {
    var source: Source {
        Source(state: state, input: input, output: output, parts: dependencies)
    }
}

extension RecurringEditModel.Source {
    func save(permission: NotificationPermission) async -> Void? {
        if let text = output.problemMessage {
            state.notices.error.show(text)
            return nil
        }

        do {
            try await dependencies.database.saveRecurring(
                output.draft,
                editing: input.editingId,
                today: input.today,
                at: dependencies.clock.now
            )

            await requestPermissionIfReminding(permission)

            return ()
        } catch {
            state.notices.error.show(SettingsEditMessage.saveFailed, for: error)
            return nil
        }
    }
}

private extension RecurringEditModel.Source {
    func requestPermissionIfReminding(_ permission: NotificationPermission) async {
        guard state.fields.schedule.remindDaysBefore != nil else {
            return
        }

        await permission.requestIfUndecided()
    }
}

extension RecurringEditModel.Source: EditFlowSource {
    var isEditing: Bool {
        output.isEditing
    }

    var isChanged: Bool {
        input.baseline.map { $0 != output.draft } ?? false
    }

    var problem: String? {
        output.problemMessage
    }

    var isHidden: Bool {
        input.isHidden
    }

    func store() async -> Void? {
        await save(permission: input.permission)
    }

    func storeHidden(_ isHidden: Bool) async throws {
        guard let editingId = input.editingId else {
            return
        }

        try await dependencies.database.setRecurringHidden(
            editingId,
            isHidden: isHidden,
            today: input.today,
            at: dependencies.clock.now
        )

        input.isHidden = isHidden
    }

    func remove() async throws -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        return try await dependencies.database.deleteRecurring(
            editingId,
            at: dependencies.clock.now
        )
    }

    func deleteFailedMessage(for _: any Error) -> String {
        SettingsEditMessage.saveFailed
    }
}
