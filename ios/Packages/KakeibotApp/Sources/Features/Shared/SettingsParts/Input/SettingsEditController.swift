import Store
import SwiftUI

@MainActor
protocol SettingsEditing: AnyObject {
    var isChanged: Bool { get }
    var isHidden: Bool { get }
    var canSave: Bool { get }

    func setHidden(_ isHidden: Bool) async -> Bool
    func delete() async -> Deletion?
}

struct SettingsEditPrompt {
    var isConfirmingDiscard = false
    var isConfirmingHideChanges = false
}

@MainActor
struct SettingsEditController<Model: SettingsEditing> {
    let model: Model
    let prompt: Binding<SettingsEditPrompt>
    let dismiss: DismissAction
    let restsOnHide: Bool
    let onRest: () -> Void
    let onHide: () -> Void
    let onDelete: (Deletion) -> Void
    let onSave: () async -> Bool

    init(
        model: Model,
        prompt: Binding<SettingsEditPrompt>,
        dismiss: DismissAction,
        restsOnHide: Bool = false,
        onRest: @escaping () -> Void,
        onHide: @escaping () -> Void,
        onDelete: @escaping (Deletion) -> Void,
        onSave: @escaping () async -> Bool
    ) {
        self.model = model
        self.prompt = prompt
        self.dismiss = dismiss
        self.restsOnHide = restsOnHide
        self.onRest = onRest
        self.onHide = onHide
        self.onDelete = onDelete
        self.onSave = onSave
    }
}

extension SettingsEditController {
    func close() {
        onRest()

        if model.isChanged {
            prompt.wrappedValue.isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save(hiding: Bool = false) async {
        onRest()

        guard await onSave() else {
            return
        }

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

        prompt.wrappedValue.isConfirmingHideChanges = true
    }

    func setHidden(_ isHidden: Bool) async {
        if restsOnHide {
            onRest()
        }

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

extension View {
    func settingsEditConfirmations(
        _ controller: SettingsEditController<some SettingsEditing>
    ) -> some View {
        confirmsUnsavedHide(
            isHidden: controller.model.isHidden,
            canSave: controller.model.canSave,
            isPresented: controller.prompt.isConfirmingHideChanges
        ) {
            Task {
                await controller.save(hiding: true)
            }
        } onDiscard: {
            Task {
                await controller.setHidden(!controller.model.isHidden)
            }
        }
        .confirmsDiscard(
            when: controller.model.isChanged,
            isPresented: controller.prompt.isConfirmingDiscard
        ) {
            controller.dismiss()
        }
    }
}
