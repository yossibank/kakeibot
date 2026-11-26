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
            onSaved: onSave,
            onSave: {
                await $0.save()
            }
        )
    }

    func addTag() {
        showTag(.add)
    }

    func editTag(_ id: UUID) {
        showTag(.rename(id))
    }

    func closeTag() {
        isTagFocused = nil

        withAnimation(.snappy(duration: 0.2)) {
            model.state.closeTag()
        }
    }

    func commitTag() {
        guard model.state.commitTag() else {
            return
        }

        closeTag()

        if startsAddingTag {
            edit.save()
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
    func showTag(_ target: TagEdit.Target) {
        focus = nil
        model.state.ignoresKeyboard = true

        withAnimation(.snappy(duration: 0.25)) {
            model.state.showTag(target)
        }
    }
}
