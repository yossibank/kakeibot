import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class TemplateEditModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output
    public let flow: EditFlow<EntryTemplate>

    let dependencies: ScreenParts

    public convenience init(
        parts: ScreenParts,
        type: Entry.Kind,
        editing id: EntryTemplate.ID? = nil
    ) {
        self.init(parts: parts, state: State(type: type, wait: parts.wait), editing: id)
    }

    public convenience init(
        parts: ScreenParts,
        draft: EntryTemplateDraft
    ) {
        let state = State(type: draft.type, wait: parts.wait)

        state.apply(draft)

        self.init(parts: parts, state: state, editing: nil)
    }

    private init(
        parts: ScreenParts,
        state: State,
        editing id: EntryTemplate.ID?
    ) {
        let input = Input(editingId: id)
        let output = Output(input: input, state: state)
        let source = Source(state: state, input: input, output: output, parts: parts)

        self.state = state
        self.input = input
        self.output = output
        self.flow = EditFlow(source: source)
        self.dependencies = parts
    }
}

public extension TemplateEditModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var options: EntryOptions?
        public internal(set) var cardBills: [Recurring] = []
        public internal(set) var baseline: EntryTemplateDraft?
        public internal(set) var isHidden = false

        public let editingId: EntryTemplate.ID?

        init(editingId: EntryTemplate.ID?) {
            self.editingId = editingId
        }
    }
}

extension TemplateEditModel {
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

public extension TemplateEditModel {
    func editCategoryModel(_ category: EntryCategory) -> CategoryEditModel {
        CategoryEditModel(
            parts: dependencies,
            kind: category.kind,
            editing: category.id
        )
    }

    func openTags() {
        if let category = output.selectedCategory {
            state.presented.tagCategory.show(category)
        }
    }

    func reloadTags() async {
        do {
            input.options = try await dependencies.database.entryOptions()
        } catch is CancellationError {
            return
        } catch {
            state.notices.error.show(Self.loadFailedMessage)
        }
    }

    func load() async {
        do {
            input.options = try await dependencies.database.entryOptions()
            input.cardBills = try await dependencies.database.recurrings()
            try await loadTemplate()

            if state.fields.categoryId == nil {
                state.setCategory(output.categories.first?.id)
            }

            if state.fields.walletId == nil {
                state.setWallet(output.wallets.first?.id)
            }

            input.baseline = output.draft
        } catch is CancellationError {
            return
        } catch {
            state.notices.error.show(Self.loadFailedMessage)
        }
    }

    @discardableResult
    func save() async -> EntryTemplate? {
        await source.store()
    }
}

extension TemplateEditModel {
    var source: Source {
        Source(state: state, input: input, output: output, parts: dependencies)
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

extension TemplateEditModel.Source: EditFlowSource {
    var isEditing: Bool {
        input.editingId != nil
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

    func store() async -> EntryTemplate? {
        if let text = output.problemMessage {
            state.notices.error.show(text)
            return nil
        }

        do {
            return try await dependencies.database.saveTemplate(
                output.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )
        } catch {
            state.notices.error.show(SettingsEditMessage.saveFailed, for: error)
            return nil
        }
    }

    func storeHidden(_ isHidden: Bool) async throws {
        guard let editingId = input.editingId else {
            return
        }

        try await dependencies.database.setHidden(
            editingId,
            isHidden: isHidden,
            at: dependencies.clock.now
        )

        input.isHidden = isHidden
    }

    func remove() async throws -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        return try await dependencies.database.deleteTemplate(editingId)
    }

    func deleteFailedMessage(for _: any Error) -> String {
        SettingsEditMessage.saveFailed
    }
}
