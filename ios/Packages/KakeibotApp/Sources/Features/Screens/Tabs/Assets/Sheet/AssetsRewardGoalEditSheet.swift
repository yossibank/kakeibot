import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct AssetsRewardGoalEditSheet: View {
    @State private var model: AssetsRewardGoalEditModel
    @State private var panel: Panel?

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    init(model: AssetsRewardGoalEditModel) {
        _model = State(initialValue: model)
        _panel = State(initialValue: model.output.isEditing ? nil : .amount)
    }

    var body: some View {
        content
            .settingsDrawerLayer(item: panel) {
                closePanel()
            } drawer: { panel in
                drawerView(panel)
            }
            .overlay(alignment: .top) {
                SettingsEditHeader(
                    title: model.output.isEditing ? "目標を編集" : "目標を決める",
                    isEditing: model.output.isEditing,
                    isHidden: false,
                    canHide: false
                ) {
                    close()
                } onHide: {} onDelete: {
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
            .confirmsDiscard(
                when: model.output.isChanged,
                isPresented: Bindable(model.state).prompt.isConfirmingDiscard
            ) {
                dismiss()
            }
            .confirmation(
                isPresented: Bindable(model.state).prompt.isConfirmingDelete,
                systemImage: "trash",
                title: "この目標を削除しますか",
                message: "貯金箱の額はそのまま残ります",
                keepTitle: "やめる",
                confirmTitle: "削除する"
            ) {
                model.perform {
                    await $0.delete()
                }
            }
            .onOutcome(model.state.outcome) { _ in
                dismiss()
            }
            .onChange(of: focus) {
                if focus != nil {
                    hidePanel()
                }
            }
            .presentationSizing(.tallForm)
    }
}

private extension AssetsRewardGoalEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 44)

            ScrollView {
                VStack(spacing: SettingsSpacing.form) {
                    AssetsRewardGoalCard(
                        name: model.state.name.isEmpty ? "欲しい物" : model.state.name,
                        targetAmount: model.state.calculator.amount,
                        remaining: model.output.remaining,
                        progress: model.output.progress
                    )
                    .sharesTextScale(id: model.state.name)

                    SettingsField(
                        "欲しい物（例：新しい靴）",
                        text: Bindable(model.state).name,
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
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
    }

    var saveButton: some View {
        PrimaryButton(model.output.saveTitle) {
            save()
        }
        .disabled(!model.output.canSave)
    }

    func drawerView(_ panel: Panel) -> some View {
        SettingsDrawer("目標の額", showsDone: false) {
            closePanel()
        } content: {
            VStack(spacing: 12) {
                Keypad(calculator: model.state.calculator) {
                    closePanel()
                } onKey: { key in
                    model.state.press(key)
                }

                saveButton
            }
        }
    }
}

private extension AssetsRewardGoalEditSheet {
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
                value: Yen.text(model.state.calculator.amount),
                isEmpty: model.state.calculator.amount == 0,
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

        if model.output.isChanged {
            model.state.prompt.isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save() {
        closePanel()

        model.perform {
            await $0.save()
        }
    }
}
