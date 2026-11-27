import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct RewardRuleEditSheet: View {
    @State private var model: RewardRuleEditModel
    @State private var layout = Layout()

    @FocusState private var focus: Field?

    @Environment(\.themeStyle.corner) private var corner

    private let onDelete: (Deletion) -> Void
    private let onHide: () -> Void

    public init(
        model: RewardRuleEditModel,
        onDelete: @escaping (Deletion) -> Void = { _ in },
        onHide: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: model)

        self.onDelete = onDelete
        self.onHide = onHide
    }

    public var body: some View {
        content
            .settingsDrawerLayer(item: model.state.panel.current) {
                closePanel()
            } drawer: { panel in
                drawerView(panel)
            }
            .iconEditorDrawer(
                model: model.state.icon,
                focus: $focus,
                textField: .text,
                below: layout.iconBottom
            )
            .overlay(alignment: .top) {
                editHeader
            }
            .background {
                Backdrop()
                    .ignoresSafeArea()
                    .onTapGesture {
                        focus = nil
                    }
            }
            .errorBanner(model.state.errorNotice)
            .editSheet(
                model.flow,
                deleting: deletion,
                onHide: onHide,
                onDelete: onDelete
            )
            .onChange(of: focus) {
                if focus != nil {
                    hidePanel()
                }
            }
            .task {
                await model.load()
            }
            .presentationSizing(.tallForm)
    }
}

private extension RewardRuleEditSheet {
    enum Field: Hashable {
        case name
        case text
    }

    struct Layout {
        var iconBottom: CGFloat = 0
    }

    typealias Panel = RewardRuleEditModel.Panel
}

private extension RewardRuleEditSheet {
    var content: some View {
        SettingsEditForm(showsSave: focus == nil) {
            tilePreview

            SettingsField(
                "自炊した日など",
                text: Bindable(model.state).fields.name,
                focus: $focus,
                field: .name
            )

            VStack(alignment: .leading, spacing: 8) {
                SettingsFormCard {
                    SettingsFormSection("金額") {
                        SettingsAmountButton(
                            amount: model.output.amount ?? 0,
                            text: amountPrompt,
                            isEmpty: (model.output.amount ?? 0) == 0
                        ) {
                            open(.amount)
                        }
                    }
                }

                SettingsCaption("達成した日に、この金額を貯金箱に貯めます。")
            }
        } save: {
            saveButton
        }
    }

    var editHeader: some View {
        SettingsEditHeader(
            isMenuOpen: Bindable(model.flow.state).prompt[.menu],
            title: model.flow.output.isEditing ? "ごほうびの決まりを編集" : "ごほうびの決まりを追加",
            isEditing: model.flow.output.isEditing,
            isHidden: model.flow.output.isHidden,
            canDelete: !(model.flow.output.isHidden && model.input.hasLogs)
        ) {
            closePanel()
            model.flow.close()
        } onHide: {
            closePanel()
            model.flow.toggleHidden()
        } onDelete: {
            model.flow.state.prompt.show(.delete)
        }
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
    }

    var tilePreview: some View {
        SettingsPreviewSection(note: "ごほうび貯金箱では、このタイルで並びます") {
            Button {
                focus = nil
                model.state.icon.present()
            } label: {
                RewardRuleTile(
                    icon: model.state.icon.preview,
                    name: model.state.fields.name.isEmpty ? "名前" : model.state.fields.name,
                    amount: model.output.amount ?? 0,
                    total: nil,
                    isHidden: false
                )
                .frame(width: 172, height: 156)
                .overlay {
                    if model.state.icon.isPresented {
                        RoundedRectangle(cornerRadius: corner.radius(16))
                            .stroke(Palette.accent, lineWidth: 2)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    EditBadge()
                        .offset(x: 4, y: 4)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .global).maxY
        } action: { maxY in
            layout.iconBottom = maxY
        }
    }

    var saveButton: some View {
        PrimaryButton(model.flow.output.saveTitle) {
            closePanel()
            model.flow.save()
        }
        .disabled(!model.flow.output.canSave)
    }

    func drawerView(_ panel: Panel) -> some View {
        SettingsDrawer("金額", showsDone: false) {
            closePanel()
        } content: {
            VStack(spacing: 12) {
                Keypad(calculator: model.state.calculator) {
                    closePanel()
                } onKey: { key in
                    model.state.press(key)
                }
            }
        }
    }
}

private extension RewardRuleEditSheet {
    var amountPrompt: String? {
        model.output.amount == nil ? "金額を入れる" : nil
    }

    var deletion: SettingsConfirmation {
        guard model.input.hasLogs else {
            return SettingsConfirmation(
                systemImage: "trash",
                title: "この決まりを削除しますか",
                message: nil,
                confirmTitle: "削除する"
            )
        }

        return SettingsConfirmation(
            systemImage: "eye.slash",
            title: "この決まりは削除できません",
            message: "貯めた記録があります。非表示にすると、貯めた分を残したまま一覧から外せます",
            confirmTitle: "非表示にする",
            role: .suggestion,
            confirmsHide: true
        )
    }

    func open(_ panel: Panel) {
        focus = nil

        withAnimation(.snappy) {
            model.state.panel.show(panel)
        }
    }

    func hidePanel() {
        withAnimation(.snappy) {
            model.state.panel.closeAll()
        }
    }

    func closePanel() {
        focus = nil
        hidePanel()
    }
}

extension RewardRuleEditSheet: SettingsEditSheet {}

#Preview {
    if let parts = ScreenParts.preview() {
        RewardRuleEditSheet(model: RewardRuleEditModel(parts: parts))
    }
}
