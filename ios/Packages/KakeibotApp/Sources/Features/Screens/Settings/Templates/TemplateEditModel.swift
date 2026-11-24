import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class TemplateEditModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        type: Entry.Kind,
        editing id: EntryTemplate.ID? = nil
    ) {
        let state = State(type: type)
        let input = Input(editingId: id)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: database, clock: clock)
    }

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        draft: EntryTemplateDraft
    ) {
        let state = State(type: draft.type)
        let input = Input(editingId: nil)

        state.apply(draft)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension TemplateEditModel {
    @MainActor
    @Observable
    final class Input: SettingsEditHidingInput {
        public internal(set) var isHidden = false
        public internal(set) var options: EntryOptions?
        public internal(set) var cardBills: [Recurring] = []

        var baseline: EntryTemplateDraft?

        let editingId: EntryTemplate.ID?

        init(editingId: EntryTemplate.ID?) {
            self.editingId = editingId
        }
    }

    func editCategoryModel(_ category: EntryCategory) -> CategoryEditModel {
        CategoryEditModel(
            database: dependencies.database,
            clock: dependencies.clock,
            kind: category.kind,
            editing: category.id
        )
    }

    func reloadTags() async {
        do {
            input.options = try await dependencies.database.entryOptions()
        } catch is CancellationError {
            return
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func load() async {
        do {
            input.options = try await dependencies.database.entryOptions()
            input.cardBills = try await dependencies.database.recurrings()

            try await loadTemplate()

            if state.categoryId == nil {
                state.setCategory(output.categories.first?.id)
            }

            if state.walletId == nil {
                state.setWallet(output.wallets.first?.id)
            }

            input.baseline = output.draft
        } catch is CancellationError {
            return
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func save() async -> EntryTemplate? {
        if let text = output.problemMessage {
            state.errorNotice.show(text)
            return nil
        }

        do {
            return try await dependencies.database.saveTemplate(
                output.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return nil
        }
    }
}

extension TemplateEditModel {
    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }
}

private extension TemplateEditModel {
    static let loadFailedMessage = "テンプレートを読めませんでした"

    func loadTemplate() async throws {
        guard let editingId = input.editingId else {
            return
        }

        let templates = try await dependencies.database.templates(includingHidden: true)
        let template = templates.first { $0.id == editingId }

        guard let template else {
            throw AppDatabase.TemplateWriteError.templateNotFound
        }

        input.isHidden = template.archivedAt != nil

        state.apply(EntryTemplateDraft(template))
    }
}

extension TemplateEditModel: SettingsEditRemoving {
    static let deleteFailedMessage = SettingsEditMessage.saveFailed

    var edited: EntryTemplateDraft {
        output.draft
    }

    var problemMessage: String? {
        output.problemMessage
    }

    func remove(_ id: EntryTemplate.ID) async throws -> Deletion {
        try await dependencies.database.deleteTemplate(id)
    }

    func saveHidden(
        _ id: EntryTemplate.ID,
        isHidden: Bool
    ) async throws {
        try await dependencies.database.setHidden(
            id,
            isHidden: isHidden,
            at: dependencies.clock.now
        )
    }
}
