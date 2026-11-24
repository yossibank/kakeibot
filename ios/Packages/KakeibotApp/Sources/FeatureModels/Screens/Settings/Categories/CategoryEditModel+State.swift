import Core
import DesignSystem
import Foundation
import Observation

public extension CategoryEditModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()

        public var name = ""

        public private(set) var tags: [EditingTag] = []
        public private(set) var tagProblem: String?

        public let icon = SettingsIconEditorModel(glyph: .food)
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

    func clearTagProblem() {
        tagProblem = nil
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
