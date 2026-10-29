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
    public private(set) var isHidden = false
    public private(set) var tagProblem: String?

    public internal(set) var errorNotice = ErrorNotice()

    public let kind: EntryCategory.Kind
    public let icon = IconEditModel(glyph: .food)

    private var baseline: Snapshot?
    private var tagWrite: Task<Void, Never>?

    private let database: AppDatabase
    private let editingId: EntryCategory.ID?

    public init(
        database: AppDatabase,
        kind: EntryCategory.Kind,
        editing id: EntryCategory.ID? = nil
    ) {
        self.database = database
        self.kind = kind
        self.editingId = id
        self.baseline = snapshot
    }
}

public extension CategoryEditModel {
    struct EditingTag: Identifiable, Hashable, Sendable {
        public let id: UUID

        public var draft: EntryTagDraft
    }

    var isEditing: Bool {
        editingId != nil
    }

    var isChanged: Bool {
        baseline.map { $0 != snapshot } ?? false
    }

    var draft: CategoryDraft {
        CategoryDraft(
            kind: kind,
            name: name,
            mark: icon.mark,
            color: icon.color
        )
    }

    var canSave: Bool {
        draft.problems.isEmpty
    }

    var saveTitle: String {
        SettingsSaveTitle.text(
            problem: draft.problems.first?.message,
            isEditing: isEditing
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
            let category = list.categories.first { $0.id == editingId }

            guard
                let category,
                let icon = list.icons[category.iconId]
            else {
                errorNotice.show(Self.loadFailedMessage)
                return
            }

            let loaded = CategoryDraft(category, icon: icon)

            apply(loaded)

            tags = list.tags.filter { $0.categoryId == editingId }.map(EditingTag.init)
            isHidden = category.archivedAt != nil
            baseline = snapshot
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func storeTags() async {
        let previous = tagWrite

        let write = Task {
            await previous?.value
            await writeTags()
        }

        tagWrite = write

        await write.value
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
            errorNotice.show(Self.saveFailedMessage, for: error)
            return nil
        }
    }

    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await database.setCategoryHidden(
                editingId,
                isHidden: isHidden,
                at: Date()
            )

            self.isHidden = isHidden

            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
            return false
        }
    }

    func delete() async -> Deletion? {
        guard let editingId else {
            return nil
        }

        do {
            return try await database.deleteCategory(
                editingId,
                at: Date()
            )
        } catch AppDatabase.CategoryWriteError.hasEntries {
            errorNotice.show(Self.inUseMessage)
            return nil
        } catch {
            errorNotice.show(Self.deleteFailedMessage, for: error)
            return nil
        }
    }
}

private extension CategoryEditModel {
    struct Snapshot: Equatable {
        let draft: CategoryDraft
        let tags: [EntryTagDraft]
    }

    static let loadFailedMessage = "カテゴリを読めませんでした"
    static let saveFailedMessage = "保存できませんでした"
    static let deleteFailedMessage = "削除できませんでした"
    static let inUseMessage = "記録があるので削除できません。非表示にできます"

    var snapshot: Snapshot {
        Snapshot(
            draft: draft,
            tags: tags.map(\.draft)
        )
    }

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

    func writeTags() async {
        guard let editingId else {
            return
        }

        let sent = tags

        do {
            let saved = try await database.saveTags(
                sent.map(\.draft),
                for: editingId,
                at: Date()
            )

            let drafts = zip(sent, saved).map { editing, tag in
                var draft = editing.draft

                draft.id = tag.id

                return draft
            }

            for (editing, draft) in zip(sent, drafts) {
                if let index = tags.firstIndex(where: { $0.id == editing.id }) {
                    tags[index].draft.id = draft.id
                }
            }

            baseline = baseline.map { Snapshot(draft: $0.draft, tags: drafts) }
        } catch {
            errorNotice.show(Self.saveFailedMessage, for: error)
        }
    }

    func apply(_ draft: CategoryDraft) {
        name = draft.name
        icon.apply(draft.icon)
    }
}

extension CategoryEditModel.EditingTag {
    init(_ tag: EntryTag) {
        self.init(id: UUID(), draft: EntryTagDraft(tag))
    }
}
