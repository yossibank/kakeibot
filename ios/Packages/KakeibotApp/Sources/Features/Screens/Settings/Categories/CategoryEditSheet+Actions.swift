import SwiftUI

extension CategoryEditSheet {
    func addTag() {
        showTag(.add, name: "")
    }

    func editTag(_ id: UUID) {
        let name = model.tags.first { $0.id == id }?.draft.name ?? ""
        showTag(.rename(id), name: name)
    }

    func closeTag() {
        isTagFocused = nil

        model.clearTagProblem()

        withAnimation(.snappy(duration: 0.2)) {
            tagEdit = nil
        }
    }

    func commitTag() {
        let isDone = switch tagEdit {
        case .add: model.addTag(tagName)
        case let .rename(id): model.renameTag(id, to: tagName)
        case nil: true
        }

        guard isDone else {
            return
        }

        closeTag()

        if startsAddingTag {
            Task {
                await save()
            }
        }
    }

    func cancelTag() {
        closeTag()

        if startsAddingTag {
            dismiss()
        }
    }

    func close() {
        focus = nil

        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save(hiding: Bool = false) async {
        focus = nil

        guard let category = await model.save() else {
            return
        }

        onSave(category)

        if hiding {
            guard await model.setHidden(!model.isHidden) else {
                return
            }

            if model.isHidden {
                onHide()
            }
        }

        dismiss()
    }

    func toggleHidden() {
        guard model.isChanged else {
            Task {
                await setHidden(!model.isHidden)
            }

            return
        }

        isConfirmingHideChanges = true
    }

    func setHidden(_ isHidden: Bool) async {
        if await model.setHidden(isHidden) {
            if isHidden {
                onHide()
            }

            dismiss()
        }
    }

    func delete() async {
        if let deletion = await model.delete() {
            onDelete(deletion)
            dismiss()
        }
    }
}

private extension CategoryEditSheet {
    func showTag(
        _ edit: TagEdit,
        name: String
    ) {
        focus = nil
        tagName = name
        ignoresKeyboard = true

        model.clearTagProblem()

        withAnimation(.snappy(duration: 0.25)) {
            tagEdit = edit
        }
    }
}
