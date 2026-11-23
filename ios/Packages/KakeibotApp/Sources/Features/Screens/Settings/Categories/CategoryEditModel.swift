import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class CategoryEditModel {
    public var name = ""

    public private(set) var tags: [EditingTag] = []

    public internal(set) var isHidden = false

    public private(set) var hasEntries = false
    public private(set) var tagProblem: String?

    public internal(set) var errorNotice = ErrorNotice()

    public let kind: EntryCategory.Kind
    public let icon = SettingsIconEditorModel(glyph: .food)

    private(set) var baseline: Snapshot?

    let editingId: EntryCategory.ID?

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        kind: EntryCategory.Kind,
        editing id: EntryCategory.ID? = nil
    ) {
        self.database = database
        self.kind = kind
        self.editingId = id
        self.baseline = edited
    }
}

public extension CategoryEditModel {
    struct EditingTag: Identifiable, Hashable, Sendable {
        public let id: UUID

        public var draft: EntryTagDraft
    }

    var draft: EntryCategoryDraft {
        EntryCategoryDraft(
            kind: kind,
            name: name,
            mark: icon.mark,
            color: icon.color
        )
    }

    func addTag(_ name: String) -> Bool {
        let draft = EntryTagDraft(name: name)

        guard check(draft, among: tags.map(\.draft)) else {
            return false
        }

        let tag = EditingTag(id: UUID(), draft: draft)

        tags.append(tag)

        return true
    }

    func renameTag(
        _ id: UUID,
        to name: String
    ) -> Bool {
        guard let index = tags.firstIndex(where: { $0.id == id }) else {
            return false
        }

        let others = tags.filter { $0.id != id }.map(\.draft)

        var draft = tags[index].draft

        draft.name = name

        guard check(draft, among: others) else {
            return false
        }

        tags[index].draft = draft

        return true
    }

    func moveTag(
        _ id: UUID,
        to index: Int
    ) {
        guard let from = tags.firstIndex(where: { $0.id == id }) else {
            return
        }

        let to = min(max(index, 0), tags.count - 1)

        guard from != to else {
            return
        }

        let tag = tags.remove(at: from)

        tags.insert(tag, at: to)
    }

    func removeTag(_ id: UUID) {
        tags.removeAll { $0.id == id }
    }

    func clearTagProblem() {
        tagProblem = nil
    }

    func load() async {
        guard let editingId else {
            return
        }

        do {
            let list = try await database.categoryList()
            let entries = try await database.entryList().entries
            let category = list.categories.first { $0.id == editingId }

            guard
                let category,
                let icon = list.icons[category.iconId]
            else {
                errorNotice.show(Self.loadFailedMessage)
                return
            }

            let loaded = EntryCategoryDraft(category, icon: icon)

            apply(loaded)

            tags = list.tags.filter { $0.categoryId == editingId }.map(EditingTag.init)
            isHidden = category.archivedAt != nil
            hasEntries = entries.contains { $0.categoryId == editingId }
            baseline = edited
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func save() async -> EntryCategory? {
        do {
            return try await database.saveCategory(
                draft,
                tags: tags.map(\.draft),
                editing: editingId,
                at: Date()
            )
        } catch {
            errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return nil
        }
    }
}

extension CategoryEditModel {
    struct Snapshot: Equatable {
        let draft: EntryCategoryDraft
        let tags: [EntryTagDraft]
    }
}

private extension CategoryEditModel {
    static let loadFailedMessage = "カテゴリを読めませんでした"
    static let inUseMessage = "記録があるので削除できません。非表示にできます"

    func check(
        _ tag: EntryTagDraft,
        among others: [EntryTagDraft]
    ) -> Bool {
        switch tag.problems(among: others).first {
        case .emptyName:
            tagProblem = "タグの名前を入れてください"
            return false

        case .nameTooLong:
            tagProblem = "タグは \(EntryTagDraft.maxNameLength) 文字までです"
            return false

        case .duplicateName:
            tagProblem = "同じ名前のタグがあります"
            return false

        case nil:
            tagProblem = nil
            return true
        }
    }

    func apply(_ draft: EntryCategoryDraft) {
        name = draft.name
        icon.apply(draft.icon)
    }
}

extension CategoryEditModel.EditingTag {
    init(_ tag: EntryTag) {
        self.init(id: UUID(), draft: EntryTagDraft(tag))
    }
}

extension CategoryEditModel: SettingsEditRemoving {
    var edited: Snapshot {
        Snapshot(
            draft: draft,
            tags: tags.map(\.draft)
        )
    }

    var problemMessage: String? {
        draft.problems.first?.message
    }

    func remove(_ id: EntryCategory.ID) async throws -> Deletion {
        try await database.deleteCategory(
            id,
            at: Date()
        )
    }

    func deleteFailedMessage(for error: any Error) -> String? {
        switch error {
        case AppDatabase.CategoryWriteError.hasEntries: Self.inUseMessage
        default: nil
        }
    }

    func saveHidden(
        _ id: EntryCategory.ID,
        isHidden: Bool
    ) async throws {
        try await database.setHidden(
            id,
            isHidden: isHidden,
            at: Date()
        )
    }
}
