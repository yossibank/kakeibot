import Core
import DesignSystem
import Foundation
import Observation

public extension CategoryEditModel {
    struct Fields: ScreenEditable {
        public var name = ""
    }

    struct Presented: ScreenEditable {
        public var isMovingTag = false
        public var ignoresKeyboard = false
    }

    struct TagEdit: Hashable, Sendable {
        public let target: Target

        public internal(set) var name: String
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var fields = Fields()
        public var presented = Presented()

        public internal(set) var ready = ScreenOutcome<Void>()

        public private(set) var tags: [EditingTag] = []
        public private(set) var tagRejection: EntryTagDraft.Problem?
        public private(set) var tagEdit: TagEdit?

        public let errorNotice: ErrorNotice
        public let icon = SettingsIconEditorModel(glyph: .food)

        init(wait: ScreenWait) {
            self.errorNotice = ErrorNotice(wait: wait)
        }
    }
}

private extension CategoryEditModel {
    static func message(for problem: EntryTagDraft.Problem) -> String {
        switch problem {
        case .emptyName: "タグの名前を入れてください"
        case .nameTooLong: "タグは \(EntryTagDraft.maxNameLength) 文字までです"
        case .duplicateName: "同じ名前のタグがあります"
        }
    }
}

public extension CategoryEditModel.TagEdit {
    enum Target: Hashable, Sendable {
        case add
        case rename(UUID)
    }
}

public extension CategoryEditModel.State {
    var tagProblem: String? {
        tagRejection.map(CategoryEditModel.message(for:))
    }

    func setMovingTag(_ isMoving: Bool) {
        if presented.isMovingTag != isMoving {
            presented.isMovingTag = isMoving
        }
    }

    func setIgnoresKeyboard(_ ignores: Bool) {
        if presented.ignoresKeyboard != ignores {
            presented.ignoresKeyboard = ignores
        }
    }

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

        tagRejection = nil
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
        if tagRejection != nil {
            tagRejection = nil
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
        fields.name = draft.name
        icon.apply(draft.icon)
        self.tags = tags
    }
}

private extension CategoryEditModel.State {
    func check(
        _ tag: EntryTagDraft,
        among others: [EntryTagDraft]
    ) -> Bool {
        tagRejection = tag.problems(among: others).first
        return tagRejection == nil
    }
}
