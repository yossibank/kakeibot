import Core
import DesignSystem
import Foundation
import Observation

public extension CategoryEditModel {
    struct Fields: ScreenEditable {
        public var name = ""

        public internal(set) var tags: [EditingTag] = []
    }

    struct Presented: ScreenEditable {
        public var isMovingTag = false
        public var ignoresKeyboard = false

        public internal(set) var tagEdit: TagEdit?
        public internal(set) var tagRejection: EntryTagDraft.Problem?
    }

    struct TagEdit: Hashable, Sendable {
        public let target: Target

        public internal(set) var name: String
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    struct Submodels {
        public let icon = SettingsIconEditorModel(glyph: .food)
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var fields = Fields()
        public var presented = Presented()

        public internal(set) var outcome = ScreenOutcome<Void>()

        public let notices: Notices
        public let submodels = Submodels()

        init(wait: ScreenWait) {
            self.notices = Notices(wait: wait)
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
        presented.tagRejection.map(CategoryEditModel.message(for:))
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

        guard check(draft, among: fields.tags.map(\.draft)) else {
            return false
        }

        let tag = CategoryEditModel.EditingTag(id: UUID(), draft: draft)

        fields.tags.append(tag)

        return true
    }

    func renameTag(
        _ id: UUID,
        to name: String
    ) -> Bool {
        guard let index = fields.tags.firstIndex(where: { $0.id == id }) else {
            return false
        }

        let others = fields.tags.filter { $0.id != id }.map(\.draft)
        var draft = fields.tags[index].draft

        draft.name = name

        guard check(draft, among: others) else {
            return false
        }

        fields.tags[index].draft = draft

        return true
    }

    func moveTag(
        _ id: UUID,
        to index: Int
    ) {
        guard let from = fields.tags.firstIndex(where: { $0.id == id }) else {
            return
        }

        let to = min(max(index, 0), fields.tags.count - 1)

        guard from != to else {
            return
        }

        let tag = fields.tags.remove(at: from)

        fields.tags.insert(tag, at: to)
    }

    func removeTag(_ id: UUID) {
        fields.tags.removeAll { $0.id == id }
    }

    func showTag(_ target: CategoryEditModel.TagEdit.Target) {
        let name = switch target {
        case .add: ""
        case let .rename(id): fields.tags.first { $0.id == id }?.draft.name ?? ""
        }

        presented.tagRejection = nil
        presented.tagEdit = CategoryEditModel.TagEdit(target: target, name: name)
    }

    func inputTag(_ name: String) {
        if let tagEdit = presented.tagEdit,
           tagEdit.name != name {
            presented.tagEdit?.name = name
        }
    }

    func commitTag() -> Bool {
        guard let tagEdit = presented.tagEdit else {
            return true
        }

        return switch tagEdit.target {
        case .add: addTag(tagEdit.name)
        case let .rename(id): renameTag(id, to: tagEdit.name)
        }
    }

    func closeTag() {
        if presented.tagRejection != nil {
            presented.tagRejection = nil
        }

        if presented.tagEdit != nil {
            presented.tagEdit = nil
        }
    }
}

extension CategoryEditModel.State {
    func apply(
        _ draft: EntryCategoryDraft,
        tags: [CategoryEditModel.EditingTag]
    ) {
        fields.name = draft.name
        submodels.icon.apply(draft.icon)
        fields.tags = tags
    }
}

private extension CategoryEditModel.State {
    func check(
        _ tag: EntryTagDraft,
        among others: [EntryTagDraft]
    ) -> Bool {
        presented.tagRejection = tag.problems(among: others).first
        return presented.tagRejection == nil
    }
}
