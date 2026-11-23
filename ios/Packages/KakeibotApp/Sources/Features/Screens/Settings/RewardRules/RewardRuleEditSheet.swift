import Core
import DesignSystem
import Store
import SwiftUI

public struct RewardRuleEditSheet: View {
    @State private var model: RewardRuleEditModel
    @State private var panel: Panel?
    @State private var isEditingIcon = false
    @State private var iconBottom: CGFloat = 0
    @State private var prompt = SettingsEditPrompt()
    @State private var isConfirmingDelete = false

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
            .settingsDrawerLayer(item: panel) {
                closePanel()
            } drawer: { panel in
                drawerView(panel)
            }
            .iconEditorDrawer(
                isPresented: $isEditingIcon,
                model: model.icon,
                focus: $focus,
                textField: .text,
                below: iconBottom
            )
            .overlay(alignment: .top) {
                SettingsEditHeader(
                    title: model.isEditing ? "ごほうびの決まりを編集" : "ごほうびの決まりを追加",
                    isEditing: model.isEditing,
                    isHidden: model.isHidden,
                    canDelete: !(model.isHidden && model.hasLogs)
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
            .background {
                Backdrop()
                    .ignoresSafeArea()
                    .onTapGesture {
                        focus = nil
                    }
            }
            .errorBanner($model.errorNotice)
            .settingsEditConfirmations(edit)
            .confirmation(
                isPresented: $isConfirmingDelete,
                systemImage: deleteImage,
                title: deleteTitle,
                message: deleteMessage,
                keepTitle: "やめる",
                confirmTitle: deleteConfirmTitle,
                role: deleteRole
            ) {
                if model.hasLogs {
                    edit.toggleHidden()
                } else {
                    Task {
                        await edit.delete()
                    }
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
    var content: some View {
        SettingsEditForm(showsSave: focus == nil) {
            SettingsPreviewSection(note: "ごほうび貯金箱では、このタイルで並びます") {
                Button {
                    focus = nil
                    isEditingIcon = true
                } label: {
                    RewardRuleTile(
                        icon: model.icon.preview,
                        name: model.name.isEmpty ? "名前" : model.name,
                        amount: model.amount ?? 0,
                        total: nil,
                        isHidden: false
                    )
                    .frame(width: 172, height: 156)
                    .overlay {
                        if isEditingIcon {
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
                iconBottom = maxY
            }

            SettingsField(
                "自炊した日など",
                text: $model.name,
                focus: $focus,
                field: .name
            )

            VStack(alignment: .leading, spacing: 8) {
                SettingsFormCard {
                    SettingsFormSection("金額") {
                        SettingsAmountButton(
                            amount: model.amount ?? 0,
                            text: amountPrompt,
                            isEmpty: (model.amount ?? 0) == 0
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
            Task {
                await edit.save()
            }
        }
        .disabled(!model.canSave)
    }

    func drawerView(_ panel: Panel) -> some View {
        SettingsDrawer("金額", showsDone: false) {
            closePanel()
        } content: {
            VStack(spacing: 12) {
                Keypad(calculator: model.calculator) {
                    closePanel()
                } onKey: { key in
                    model.press(key)
                }
            }
        }
    }
}

private extension RewardRuleEditSheet {
    enum Field: Hashable {
        case name
        case text
    }

    enum Panel: Hashable {
        case amount
    }

    var amountPrompt: String? {
        model.amount == nil ? "金額を入れる" : nil
    }

    var deleteImage: String {
        model.hasLogs ? "eye.slash" : "trash"
    }

    var deleteTitle: String {
        model.hasLogs ? "この決まりは削除できません" : "この決まりを削除しますか"
    }

    var deleteMessage: String? {
        model.hasLogs ? "貯めた記録があります。非表示にすると、貯めた分を残したまま一覧から外せます" : nil
    }

    var deleteConfirmTitle: String {
        model.hasLogs ? "非表示にする" : "削除する"
    }

    var deleteRole: ConfirmCard.Role {
        model.hasLogs ? .suggestion : .destructive
    }

    var edit: SettingsEditController<RewardRuleEditModel> {
        SettingsEditController(
            model: model,
            prompt: $prompt,
            dismiss: dismiss,
            restsOnHide: true,
            onRest: {
                closePanel()
            },
            onHide: onHide,
            onDelete: onDelete,
            onSave: {
                await model.save()
            }
        )
    }

    func open(_ panel: Panel) {
        focus = nil

        withAnimation(.snappy) {
            self.panel = panel
        }
    }

    func hidePanel() {
        withAnimation(.snappy) {
            panel = nil
        }
    }

    func closePanel() {
        focus = nil
        hidePanel()
    }
}

extension RewardRuleEditModel: SettingsEditing {}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        RewardRuleEditSheet(model: RewardRuleEditModel(database: database))
    }
}

extension RewardRuleEditSheet: SettingsEditSheet {}
