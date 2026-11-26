import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct StampEditSheet: View {
    @State private var model: StampEditModel

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    private let onDelete: (Deletion) -> Void
    private let onHide: () -> Void

    public init(
        model: StampEditModel,
        onDelete: @escaping (Deletion) -> Void = { _ in },
        onHide: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: model)

        self.onDelete = onDelete
        self.onHide = onHide
    }

    public var body: some View {
        SettingsEditForm(showsSave: focus == nil) {
            SettingsPreviewSection(note: "カレンダーの日に、このスタンプで押します") {
                StampTileFace(icon: model.state.icon.preview, isHidden: false)
                    .frame(width: 80, height: 78)
            }

            SettingsFormCard {
                SettingsIconEditor(
                    model: model.state.icon,
                    focus: $focus,
                    textField: .text
                )
            }
        } save: {
            PrimaryButton(model.saveTitle) {
                edit.save()
            }
            .disabled(!model.canSave)
        }
        .overlay(alignment: .top) {
            SettingsEditHeader(
                isMenuOpen: Bindable(model.state).prompt.isMenuOpen,
                title: model.isEditing ? "スタンプを編集" : "スタンプを追加",
                isEditing: model.isEditing,
                isHidden: model.input.isHidden
            ) {
                edit.close()
            } onHide: {
                edit.toggleHidden()
            } onDelete: {
                model.state.prompt.isConfirmingDelete = true
            }
            .padding(.horizontal, SettingsSpacing.side)
            .padding(.top, SettingsSpacing.top)
        }
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
        .backdrop()
        .errorBanner(Bindable(model.state).errorNotice)
        .settingsEditConfirmations(edit)
        .confirmation(
            isPresented: Bindable(model.state).prompt.isConfirmingDelete,
            systemImage: "trash",
            title: "このスタンプを削除しますか",
            message: "カレンダーに押したスタンプは残ります",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            edit.delete()
        }
        .task {
            await model.load()
        }
        .presentationSizing(.tallForm)
    }
}

private extension StampEditSheet {
    enum Field: Hashable {
        case text
    }
}

private extension StampEditSheet {
    var edit: SettingsEditController<StampEditModel> {
        SettingsEditController(
            model: model,
            dismiss: dismiss,
            restsOnHide: true,
            onRest: {
                focus = nil
            },
            onHide: onHide,
            onDelete: onDelete,
            onSave: {
                await $0.save()
            }
        )
    }
}

extension StampEditSheet: SettingsEditSheet {}

#Preview {
    if let parts = ScreenParts.preview() {
        StampEditSheet(model: StampEditModel(parts: parts))
    }
}
