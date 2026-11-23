import Core
import DesignSystem
import Store
import SwiftUI

public struct StampEditSheet: View {
    @State private var model: StampEditModel
    @State private var prompt = SettingsEditPrompt()
    @State private var isConfirmingDelete = false

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
                StampTileFace(icon: model.icon.preview, isHidden: false)
                    .frame(width: 80, height: 78)
            }

            SettingsFormCard {
                SettingsIconEditor(
                    model: model.icon,
                    focus: $focus,
                    textField: .text
                )
            }
        } save: {
            PrimaryButton(model.saveTitle) {
                Task {
                    await edit.save()
                }
            }
            .disabled(!model.canSave)
        }
        .overlay(alignment: .top) {
            SettingsEditHeader(
                title: model.isEditing ? "スタンプを編集" : "スタンプを追加",
                isEditing: model.isEditing,
                isHidden: model.isHidden
            ) {
                edit.close()
            } onHide: {
                edit.toggleHidden()
            } onDelete: {
                isConfirmingDelete = true
            }
            .padding(.horizontal, SettingsSpacing.side)
            .padding(.top, SettingsSpacing.top)
        }
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
        .backdrop()
        .errorBanner($model.errorNotice)
        .settingsEditConfirmations(edit)
        .confirmation(
            isPresented: $isConfirmingDelete,
            systemImage: "trash",
            title: "このスタンプを削除しますか",
            message: "カレンダーに押したスタンプは残ります",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            Task {
                await edit.delete()
            }
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

    var edit: SettingsEditController<StampEditModel> {
        SettingsEditController(
            model: model,
            prompt: $prompt,
            dismiss: dismiss,
            restsOnHide: true,
            onRest: {
                focus = nil
            },
            onHide: onHide,
            onDelete: onDelete,
            onSave: {
                await model.save()
            }
        )
    }
}

extension StampEditModel: SettingsEditing {}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        StampEditSheet(model: StampEditModel(database: database))
    }
}
