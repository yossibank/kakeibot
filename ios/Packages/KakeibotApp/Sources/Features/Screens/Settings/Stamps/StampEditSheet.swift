import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct StampEditSheet: View {
    @State private var model: StampEditModel

    @FocusState private var focus: Field?

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
            PrimaryButton(model.flow.output.saveTitle) {
                focus = nil
                model.flow.save()
            }
            .disabled(!model.flow.output.canSave)
        }
        .overlay(alignment: .top) {
            SettingsEditHeader(
                isMenuOpen: Bindable(model.flow.state).prompt[.menu],
                title: model.flow.output.isEditing ? "スタンプを編集" : "スタンプを追加",
                isEditing: model.flow.output.isEditing,
                isHidden: model.flow.output.isHidden
            ) {
                focus = nil
                model.flow.close()
            } onHide: {
                focus = nil
                model.flow.toggleHidden()
            } onDelete: {
                model.flow.state.prompt.show(.delete)
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
        .editSheet(
            model.flow,
            deleting: "このスタンプを削除しますか",
            note: "カレンダーに押したスタンプは残ります",
            onHide: onHide,
            onDelete: onDelete
        )
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

extension StampEditSheet: SettingsEditSheet {}

#Preview {
    if let parts = ScreenParts.preview() {
        StampEditSheet(model: StampEditModel(parts: parts))
    }
}
