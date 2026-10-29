import Core
import DesignSystem
import Store
import SwiftUI

public struct RewardRuleEditSheet: View {
    @State private var model: RewardRuleEditModel
    @State private var panel: Panel?
    @State private var isEditingIcon = false
    @State private var iconBottom: CGFloat = 0
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingHideChanges = false
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
        ZStack(alignment: .bottom) {
            content

            if let panel {
                Palette.scrim
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closePanel()
                    }
                    .transition(.opacity)
                    .zIndex(1)

                drawerView(panel)
                    .transition(.settingsDrawer)
                    .zIndex(1)
            }
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
                title: model.isEditing ? "ごほうびを編集" : "ごほうびを追加",
                isEditing: model.isEditing,
                isHidden: model.isHidden,
                canDelete: !(model.isHidden && model.hasLogs)
            ) {
                close()
            } onHide: {
                toggleHidden()
            } onDelete: {
                isConfirmingDelete = true
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
                .onTapGesture {
                    focus = nil
                }
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .confirmsUnsavedHide(
            isHidden: model.isHidden,
            canSave: model.canSave,
            isPresented: $isConfirmingHideChanges
        ) {
            Task {
                await save(hiding: true)
            }
        } onDiscard: {
            Task {
                await setHidden(!model.isHidden)
            }
        }
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
        }
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
                toggleHidden()
            } else {
                Task {
                    await delete()
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
    }
}

private extension RewardRuleEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 44)

            ScrollView {
                VStack(spacing: 16) {
                    Button {
                        focus = nil
                        isEditingIcon = true
                    } label: {
                        IconBadge(model.icon.preview, size: 86)
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: corner.radius(86 * 0.3),
                                    style: .continuous
                                )
                                .stroke(iconStroke, lineWidth: iconStrokeWidth)
                            }
                            .overlay(alignment: .bottomTrailing) {
                                EditBadge()
                                    .offset(x: 4, y: 4)
                            }
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
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
                        SettingsRowList(items: rowItems) { panel in
                            open(panel)
                        }

                        Text("達成した日に、この金額を貯金箱に貯めます")
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                            .padding(.leading, 8)
                    }
                }
                .padding(.bottom, 8)
                .padding(.vertical, Self.fade)
            }
            .scrollIndicators(.hidden)
            .edgeFade(Self.fade)
            .padding(.vertical, -Self.fade)
            .scrollDismissesKeyboard(.interactively)

            saveButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    var saveButton: some View {
        PrimaryButton(model.saveTitle) {
            Task {
                await save()
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

                saveButton
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

    static let fade: CGFloat = 16

    var iconStroke: Color {
        isEditingIcon ? Palette.accent : Palette.outline
    }

    var iconStrokeWidth: CGFloat {
        isEditingIcon ? 2 : 1
    }

    var amountValue: String {
        AmountText.text(model.amount ?? 0)
    }

    var deleteImage: String {
        model.hasLogs ? "eye.slash" : "trash"
    }

    var deleteTitle: String {
        model.hasLogs ? "このごほうびは削除できません" : "このごほうびを削除しますか"
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

    var rowItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .amount,
                systemImage: "yensign",
                title: "金額",
                value: amountValue,
                isEmpty: model.amount == nil,
                isAmount: true
            )
        ]
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

    func close() {
        closePanel()

        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save(hiding: Bool = false) async {
        closePanel()

        if await model.save() {
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
    }

    func toggleHidden() {
        guard model.isChanged else {
            Task {
                await setHidden(!model.isHidden)
            }

            return
        }

        isConfirmingHideChanges = true
    }

    func setHidden(_ isHidden: Bool) async {
        closePanel()

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

#Preview {
    if let database = try? AppDatabase.inMemory() {
        RewardRuleEditSheet(model: RewardRuleEditModel(database: database))
    }
}
