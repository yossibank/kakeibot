import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class CategoryEditModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        clock: ScreenClock,
        kind: EntryCategory.Kind,
        editing id: EntryCategory.ID? = nil
    ) {
        let state = State()
        let input = Input(kind: kind, editingId: id)
        let output = Output(input: input, state: state)

        input.baseline = output.snapshot

        self.state = state
        self.input = input
        self.output = output
        self.dependencies = Dependencies(database: database, clock: clock)
    }
}

public extension CategoryEditModel {
    struct EditingTag: Identifiable, Hashable, Sendable {
        public let id: UUID

        public var draft: EntryTagDraft
    }

    @MainActor
    @Observable
    final class Input: SettingsEditHidingInput {
        public internal(set) var isHidden = false
        public internal(set) var hasEntries = false

        public let kind: EntryCategory.Kind

        public internal(set) var baseline: Snapshot?

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

        public var draft: EntryCategoryDraft {
            EntryCategoryDraft(
                kind: input.kind,
                name: state.name,
                mark: state.icon.mark,
                color: state.icon.color
            )
        }

        var snapshot: Snapshot {
            Snapshot(
                draft: draft,
                tags: state.tags.map(\.draft)
            )
        }

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
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

            input.isHidden = category.archivedAt != nil
            input.hasEntries = entries.contains { $0.categoryId == editingId }
            input.baseline = output.snapshot
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func save() async -> EntryCategory? {
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
}

extension CategoryEditModel {
    public struct Snapshot: Equatable {
        let draft: EntryCategoryDraft
        let tags: [EntryTagDraft]
    }

    struct Dependencies {
        let database: AppDatabase
        let clock: ScreenClock
    }
}

private extension CategoryEditModel {
    static let loadFailedMessage = "カテゴリを読めませんでした"
    static let inUseMessage = "記録があるので削除できません。非表示にできます"
}

extension CategoryEditModel.EditingTag {
    init(_ tag: EntryTag) {
        self.init(id: UUID(), draft: EntryTagDraft(tag))
    }
}

extension CategoryEditModel: SettingsEditRemoving {
    public var edited: Snapshot {
        output.snapshot
    }

    public var problemMessage: String? {
        output.draft.problems.first?.message
    }

    public func remove(_ id: EntryCategory.ID) async throws -> Deletion {
        try await dependencies.database.deleteCategory(
            id,
            at: dependencies.clock.now
        )
    }

    public func deleteFailedMessage(for error: any Error) -> String? {
        switch error {
        case AppDatabase.CategoryWriteError.hasEntries: Self.inUseMessage
        default: nil
        }
    }

    public func saveHidden(
        _ id: EntryCategory.ID,
        isHidden: Bool
    ) async throws {
        try await dependencies.database.setHidden(
            id,
            isHidden: isHidden,
            at: dependencies.clock.now
        )

        input.isHidden = isHidden
    }
}
