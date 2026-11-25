import Core
import DesignSystem
import Foundation
import Observation

public extension CategoryEditModel {
    struct TagEdit: Hashable, Sendable {
        public let target: Target

        public internal(set) var name: String
    }

    @MainActor
    @Observable
    final class State: SettingsEditState {
        public var errorNotice = ErrorNotice()
        public var prompt = SettingsEditPrompt<Never>()
        public var outcome = ScreenOutcome<SettingsEditOutcome<EntryCategory>>()

        public var name = ""
        public var isMovingTag = false
        public var ignoresKeyboard = false

        public internal(set) var ready = ScreenOutcome<Void>()

        public private(set) var tags: [EditingTag] = []
        public private(set) var tagProblem: String?
        public private(set) var tagEdit: TagEdit?

        public let icon = SettingsIconEditorModel(glyph: .food)
    }
}

public extension CategoryEditModel.TagEdit {
    enum Target: Hashable, Sendable {
        case add
        case rename(UUID)
    }
}

public extension CategoryEditModel.State {
    func addTag(_ name: String) -> Bool {
        let draft = EntryTagDraft(name: name)

        guard check(draft, among: tags.map(\.draft)) else {
            return false
        }

        let tag = CategoryEditModel.EditingTag(id: UUID(), draft: draft)

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

    func showTag(_ target: CategoryEditModel.TagEdit.Target) {
        let name = switch target {
        case .add: ""
        case let .rename(id): tags.first { $0.id == id }?.draft.name ?? ""
        }

        tagProblem = nil
        tagEdit = CategoryEditModel.TagEdit(target: target, name: name)
    }

    func inputTag(_ name: String) {
        if let tagEdit,
           tagEdit.name != name {
            self.tagEdit?.name = name
        }
    }

    func commitTag() -> Bool {
        guard let tagEdit else {
            return true
        }

        return switch tagEdit.target {
        case .add: addTag(tagEdit.name)
        case let .rename(id): renameTag(id, to: tagEdit.name)
        }
    }

    func closeTag() {
        if tagProblem != nil {
            tagProblem = nil
        }

        if tagEdit != nil {
            tagEdit = nil
        }
    }
}

extension CategoryEditModel.State {
    func apply(
        _ draft: EntryCategoryDraft,
        tags: [CategoryEditModel.EditingTag]
    ) {
        name = draft.name
        icon.apply(draft.icon)

        self.tags = tags
    }
}

private extension CategoryEditModel.State {
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
}
