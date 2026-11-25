import Core
import FeatureModels
import SwiftUI

extension CategoryEditSheet {
    var edit: SettingsEditController<CategoryEditModel> {
        SettingsEditController(
            model: model,
            dismiss: dismiss,
            onRest: {
                focus = nil
            },
            onHide: onHide,
            onDelete: onDelete,
            onSave: {
                guard let category = await model.save() else {
                    return false
                }

                onSave(category)
                return true
            }
        )
    }

    func addTag() {
        showTag(.add, name: "")
    }

    func editTag(_ id: UUID) {
        let name = model.state.tags.first { $0.id == id }?.draft.name ?? ""
        showTag(.rename(id), name: name)
    }

    func closeTag() {
        isTagFocused = nil

        model.state.clearTagProblem()

        withAnimation(.snappy(duration: 0.2)) {
            tagEdit = nil
        }
    }

    func commitTag() {
        let isDone = switch tagEdit {
        case .add: model.state.addTag(tagName)
        case let .rename(id): model.state.renameTag(id, to: tagName)
        case nil: true
        }

        guard isDone else {
            return
        }

        closeTag()

        if startsAddingTag {
            Task {
                await edit.save()
            }
        }
    }

    func cancelTag() {
        closeTag()

        if startsAddingTag {
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

        model.state.clearTagProblem()

        withAnimation(.snappy(duration: 0.25)) {
            tagEdit = edit
        }
    }
}
