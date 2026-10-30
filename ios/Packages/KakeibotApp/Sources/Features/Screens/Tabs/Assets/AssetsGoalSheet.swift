import Core
import DesignSystem
import SwiftUI

struct AssetsGoalSheet: View {
    @State private var model: AssetsGoalEditModel
    @State private var panel: Panel?
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingDelete = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    init(model: AssetsGoalEditModel) {
        _model = State(initialValue: model)
        _panel = State(initialValue: model.isEditing ? nil : .amount)
    }

    var body: some View {
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
            SettingsEditHeader(
                title: model.isEditing ? "目標を編集" : "目標を決める",
                isEditing: model.isEditing,
                isHidden: false,
                canHide: false
            ) {
                close()
            } onHide: {} onDelete: {
                isConfirmingDelete = true
            }
            .padding(.horizontal, 20)
            .padding(.top, SettingsSpacing.top)
        }
        .background {
            Backdrop()
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
            title: "この目標を削除しますか",
            message: "貯金箱の額はそのまま残ります",
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
    }
}

private extension AssetsGoalSheet {
    var content: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 44)

            ScrollView {
                VStack(spacing: SettingsSpacing.form) {
                    AssetsGoalCard(
                        name: model.name.isEmpty ? "欲しい物" : model.name,
                        targetAmount: model.calculator.amount,
                        remaining: model.remaining,
                        progress: model.progress
                    )
                    .sharesTextScale(id: model.name)

                    SettingsField(
                        "欲しい物（例：新しい靴）",
                        text: $model.name,
                        focus: $focus,
                        field: .name
                    )

                    SettingsRowList(items: rowItems) { panel in
                        open(panel)
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
        .padding(.top, SettingsSpacing.top)
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
        SettingsDrawer("目標の額", showsDone: false) {
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

private extension AssetsGoalSheet {
    enum Field: Hashable {
        case name
    }

    enum Panel: Hashable {
        case amount
    }

    static let fade: CGFloat = 16

    var rowItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .amount,
                systemImage: "yensign",
                title: "目標の額",
                value: AmountText.text(model.calculator.amount),
                isEmpty: model.calculator.amount == 0,
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

    func delete() async {
        if await model.delete() {
            dismiss()
        }
    }
}
