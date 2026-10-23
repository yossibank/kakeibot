import Core
import DesignSystem
import Store
import SwiftUI

public struct RewardRuleEditSheet: View {
    @State private var model: RewardRuleEditModel
    @State private var panel: Panel?
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingDelete = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    private let onDelete: (Deletion) -> Void

    public init(
        model: RewardRuleEditModel,
        onDelete: @escaping (Deletion) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)

        self.onDelete = onDelete
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
        .overlay(alignment: .top) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 18)
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
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
        }
        .confirmation(
            isPresented: $isConfirmingDelete,
            systemImage: "trash",
            title: "このごほうびを削除しますか",
            message: "このごほうびで貯めた記録も消えます",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            Task {
                await delete()
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
                    IconBadge(model.icon.preview, size: 86)

                    SettingsField(
                        "名前（例：自炊した日）",
                        text: $model.name,
                        focus: $focus,
                        field: .name
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        SettingsRowList(items: rowItems) { panel in
                            open(panel)
                        }

                        Text("達成した日に、この額を貯金箱に貯めます")
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                            .padding(.leading, 6)
                    }

                    IconEditor(
                        model: model.icon,
                        focus: $focus,
                        textField: .text
                    )
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
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    var header: some View {
        SettingsEditHeader(
            title: model.isEditing ? "ごほうびを編集" : "ごほうびを追加",
            isEditing: model.isEditing,
            isHidden: model.isHidden
        ) {
            close()
        } onHide: {
            Task {
                await setHidden(!model.isHidden)
            }
        } onDelete: {
            isConfirmingDelete = true
        }
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
        SettingsDrawer("貯める額") {
            closePanel()
        } content: {
            VStack(spacing: 10) {
                Keypad(activeTax: model.calculator.taxNote?.rate) { key in
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

    var amountValue: String {
        model.amount.map { AmountText.text($0) } ?? "入れる"
    }

    var rowItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .amount,
                systemImage: "yensign",
                title: "貯める額",
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

    func save() async {
        closePanel()

        if await model.save() {
            dismiss()
        }
    }

    func setHidden(_ isHidden: Bool) async {
        closePanel()

        if await model.setHidden(isHidden) {
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
