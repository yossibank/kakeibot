import Core
import DesignSystem
import FeatureModels
import SwiftUI

private struct EditSheetOutcome<Saved: Sendable>: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    let flow: EditFlow<Saved>
    let onHide: () -> Void
    let onDelete: (Deletion) -> Void
    let onSaved: (Saved) -> Void

    func body(content: Content) -> some View {
        content
            .confirmsDiscard(
                when: flow.output.isChanged,
                isPresented: Bindable(flow.state).prompt[.discard]
            ) {
                flow.discard()
            }
            .onOutcome(flow.state.outcome) { outcome in
                receive(outcome)
            }
    }
}

private extension EditSheetOutcome {
    func receive(_ outcome: EditFlow<Saved>.Outcome) {
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
    func editSheet<Saved>(
        _ flow: EditFlow<Saved>,
        deleting title: String,
        note: String,
        onHide: @escaping () -> Void = {},
        onDelete: @escaping (Deletion) -> Void = { _ in },
        onSaved: @escaping (Saved) -> Void = { _ in }
    ) -> some View {
        editSheet(
            flow,
            deleting: .delete(title: title, message: note),
            onHide: onHide,
            onDelete: onDelete,
            onSaved: onSaved
        )
    }

    func editSheet<Saved>(
        _ flow: EditFlow<Saved>,
        deleting confirmation: SettingsConfirmation? = nil,
        hiding hideConfirmation: SettingsConfirmation? = nil,
        onHide: @escaping () -> Void = {},
        onDelete: @escaping (Deletion) -> Void = { _ in },
        onSaved: @escaping (Saved) -> Void = { _ in }
    ) -> some View {
        confirmsUnsavedHide(
            isHidden: flow.output.isHidden,
            canSave: flow.output.canSave,
            isPresented: Bindable(flow.state).prompt[.hideChanges]
        ) {
            flow.saveTogglingHidden()
        } onDiscard: {
            flow.setHidden(!flow.output.isHidden)
        }
        .settingsConfirmation(
            hideConfirmation,
            isPresented: Bindable(flow.state).prompt[.hide]
        ) {
            flow.continueHiding()
        }
        .settingsConfirmation(
            confirmation,
            isPresented: Bindable(flow.state).prompt[.delete]
        ) {
            if confirmation?.confirmsHide == true {
                flow.toggleHidden()
            } else {
                flow.delete()
            }
        }
        .modifier(
            EditSheetOutcome(
                flow: flow,
                onHide: onHide,
                onDelete: onDelete,
                onSaved: onSaved
            )
        )
    }
}
