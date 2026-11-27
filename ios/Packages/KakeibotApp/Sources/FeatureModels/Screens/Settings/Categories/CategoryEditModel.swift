import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class CategoryEditModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output
    public let flow: EditFlow<EntryCategory>

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        kind: EntryCategory.Kind,
        editing id: EntryCategory.ID? = nil
    ) {
        let state = State(wait: parts.wait)
        let input = Input(kind: kind, editingId: id)
        let output = Output(input: input, state: state)
        let source = Source(state: state, input: input, output: output, parts: parts)

        self.state = state
        self.input = input
        self.output = output
        self.flow = EditFlow(source: source)
        self.dependencies = parts

        input.baseline = output.snapshot
    }
}

public extension CategoryEditModel {
    struct EditingTag: Identifiable, Hashable, Sendable {
        public let id: UUID

        public var draft: EntryTagDraft
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var hasEntries = false
        public internal(set) var baseline: Snapshot?
        public internal(set) var isHidden = false

        public let kind: EntryCategory.Kind
        public let editingId: EntryCategory.ID?

        init(
            kind: EntryCategory.Kind,
            editingId: EntryCategory.ID?
        ) {
            self.kind = kind
            self.editingId = editingId
        }
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }

    struct Snapshot: Equatable {
        let draft: EntryCategoryDraft
        let tags: [EntryTagDraft]
    }
}

extension CategoryEditModel {
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

public extension CategoryEditModel {
    func start() async {
        await load()
        state.ready.send(())
    }

    func load() async {
        guard let editingId = input.editingId else {
            return
        }

        do {
            let list = try await dependencies.database.categoryList()
            let entries = try await dependencies.database.entryList().entries
            let category = list.categories.first { $0.id == editingId }

            guard
                let category,
                let icon = list.icons[category.iconId]
            else {
                state.errorNotice.show(Self.loadFailedMessage)
                return
            }

            let loaded = EntryCategoryDraft(category, icon: icon)
            let tags = list.tags.filter { $0.categoryId == editingId }

            state.apply(loaded, tags: tags.map(EditingTag.init))
            input.hasEntries = entries.contains { $0.categoryId == editingId }
            input.isHidden = category.archivedAt != nil
            input.baseline = output.snapshot
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    @discardableResult
    func save() async -> EntryCategory? {
        await source.store()
    }
}

extension CategoryEditModel {
    var source: Source {
        Source(state: state, input: input, output: output, parts: dependencies)
    }
}

private extension CategoryEditModel {
    static let loadFailedMessage = "カテゴリを読めませんでした"
    static let inUseMessage = "記録があるので削除できません。非表示にできます"
}

public extension CategoryEditModel.Output {
    var draft: EntryCategoryDraft {
        EntryCategoryDraft(
            kind: input.kind,
            name: state.fields.name,
            mark: state.icon.mark,
            color: state.icon.color
        )
    }
}

extension CategoryEditModel.Output {
    var snapshot: CategoryEditModel.Snapshot {
        CategoryEditModel.Snapshot(
            draft: draft,
            tags: state.tags.map(\.draft)
        )
    }
}

extension CategoryEditModel.EditingTag {
    init(_ tag: EntryTag) {
        self.init(id: UUID(), draft: EntryTagDraft(tag))
    }
}

extension CategoryEditModel.Source: EditFlowSource {
    var isEditing: Bool {
        input.editingId != nil
    }

    var isChanged: Bool {
        input.baseline.map { $0 != output.snapshot } ?? false
    }

    var problem: String? {
        output.draft.problems.first?.message
    }

    var isHidden: Bool {
        input.isHidden
    }

    func store() async -> EntryCategory? {
        do {
            return try await dependencies.database.saveCategory(
                output.draft,
                tags: state.tags.map(\.draft),
                editing: input.editingId,
                at: dependencies.clock.now
            )
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return nil
        }
    }

    func remove() async throws -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        return try await dependencies.database.deleteCategory(
            editingId,
            at: dependencies.clock.now
        )
    }

    func deleteFailedMessage(for error: any Error) -> String {
        switch error {
        case AppDatabase.CategoryWriteError.hasEntries: CategoryEditModel.inUseMessage
        default: SettingsEditMessage.deleteFailed
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
}
