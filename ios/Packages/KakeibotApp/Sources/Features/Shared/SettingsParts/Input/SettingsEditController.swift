import Core
import DesignSystem
import FeatureModels
import SwiftUI

@MainActor
struct SettingsEditController<Model: SettingsEditRemoving> {
    let model: Model
    let dismiss: DismissAction
    let restsOnHide: Bool
    let onRest: () -> Void
    let onHide: () -> Void
    let onDelete: (Deletion) -> Void
    let onSaved: (Model.State.Saved) -> Void
    let onSave: @MainActor (Model) async -> Void

    init(
        model: Model,
        dismiss: DismissAction,
        restsOnHide: Bool = false,
        onRest: @escaping () -> Void,
        onHide: @escaping () -> Void,
        onDelete: @escaping (Deletion) -> Void,
        onSaved: @escaping (Model.State.Saved) -> Void = { _ in },
        onSave: @escaping @MainActor (Model) async -> Void
    ) {
        self.model = model
        self.dismiss = dismiss
        self.restsOnHide = restsOnHide
        self.onRest = onRest
        self.onHide = onHide
        self.onDelete = onDelete
        self.onSaved = onSaved
        self.onSave = onSave
    }
}

extension SettingsEditController {
    func close() {
        onRest()

        if model.isChanged {
            model.state.prompt.isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save() {
        onRest()
        model.perform(onSave)
    }

    func saveTogglingHidden() {
        onRest()

        let onSave = onSave

        model.perform {
            await $0.saveTogglingHidden(onSave)
        }
    }

    func toggleHidden() {
        guard model.isChanged else {
            setHidden(!model.isHidden)
            return
        }

        model.state.prompt.isConfirmingHideChanges = true
    }

    func setHidden(_ isHidden: Bool) {
        if restsOnHide {
            onRest()
        }

        model.perform {
            await $0.setHidden(isHidden)
        }
    }

    func delete() {
        model.perform {
            await $0.delete()
        }
    }

    func receive(_ outcome: SettingsEditOutcome<Model.State.Saved>) {
        if let saved = outcome.saved {
            onSaved(saved)
        }

        if outcome.isHidden == true {
            onHide()
        }

        if let deletion = outcome.deletion {
            onDelete(deletion)
        }

        if outcome.closes {
            dismiss()
        }
    }
}

extension View {
    func settingsEditConfirmations(
        _ controller: SettingsEditController<some SettingsEditRemoving>
    ) -> some View {
        confirmsUnsavedHide(
            isHidden: controller.model.isHidden,
            canSave: controller.model.canSave,
            isPresented: Bindable(controller.model.state).prompt.isConfirmingHideChanges
        ) {
            controller.saveTogglingHidden()
        } onDiscard: {
            controller.setHidden(!controller.model.isHidden)
        }
        .confirmsDiscard(
            when: controller.model.isChanged,
            isPresented: Bindable(controller.model.state).prompt.isConfirmingDiscard
        ) {
            controller.dismiss()
        }
        .onOutcome(controller.model.state.outcome) { outcome in
            controller.receive(outcome)
        }
    }
}
