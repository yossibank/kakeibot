import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct RewardRuleEditSheet: View {
    @State private var model: RewardRuleEditModel
    @State private var layout = Layout()

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss
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
            .settingsDrawerLayer(item: model.state.prompt.panel) {
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
                SettingsEditHeader(
                    isMenuOpen: Bindable(model.state).prompt.isMenuOpen,
                    title: model.isEditing ? "ごほうびの決まりを編集" : "ごほうびの決まりを追加",
                    isEditing: model.isEditing,
                    isHidden: model.input.isHidden,
                    canDelete: !(model.input.isHidden && model.input.hasLogs)
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
            .background {
                Backdrop()
                    .ignoresSafeArea()
                    .onTapGesture {
                        focus = nil
                    }
            }
            .errorBanner(Bindable(model.state).errorNotice)
            .settingsEditConfirmations(edit)
            .confirmation(
                isPresented: Bindable(model.state).prompt.isConfirmingDelete,
                systemImage: deleteImage,
                title: deleteTitle,
                message: deleteMessage,
                keepTitle: "やめる",
                confirmTitle: deleteConfirmTitle,
                role: deleteRole
            ) {
                if model.input.hasLogs {
                    edit.toggleHidden()
                } else {
                    edit.delete()
                }
            }
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
            SettingsPreviewSection(note: "ごほうび貯金箱では、このタイルで並びます") {
                Button {
                    focus = nil
                    model.state.icon.present()
                } label: {
                    RewardRuleTile(
                        icon: model.state.icon.preview,
                        name: model.state.name.isEmpty ? "名前" : model.state.name,
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

            SettingsField(
                "自炊した日など",
                text: Bindable(model.state).name,
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

    var saveButton: some View {
        PrimaryButton(model.saveTitle) {
            edit.save()
        }
        .disabled(!model.canSave)
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

    var deleteImage: String {
        model.input.hasLogs ? "eye.slash" : "trash"
    }

    var deleteTitle: String {
        model.input.hasLogs ? "この決まりは削除できません" : "この決まりを削除しますか"
    }

    var deleteMessage: String? {
        model.input.hasLogs ? "貯めた記録があります。非表示にすると、貯めた分を残したまま一覧から外せます" : nil
    }

    var deleteConfirmTitle: String {
        model.input.hasLogs ? "非表示にする" : "削除する"
    }

    var deleteRole: ConfirmCard.Role {
        model.input.hasLogs ? .suggestion : .destructive
    }

    var edit: SettingsEditController<RewardRuleEditModel> {
        SettingsEditController(
            model: model,
            dismiss: dismiss,
            restsOnHide: true,
            onRest: {
                closePanel()
            },
            onHide: onHide,
            onDelete: onDelete,
            onSave: {
                await $0.save()
            }
        )
    }

    func open(_ panel: Panel) {
        focus = nil

        withAnimation(.snappy) {
            model.state.open(panel)
        }
    }

    func hidePanel() {
        withAnimation(.snappy) {
            model.state.closePanel()
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
