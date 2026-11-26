import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct AssetsRewardGoalEditSheet: View {
    @State private var model: AssetsRewardGoalEditModel

    @FocusState private var focus: Field?

    init(model: AssetsRewardGoalEditModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        content
            .settingsDrawerLayer(item: model.state.panel.current) {
                closePanel()
            } drawer: { panel in
                drawerView(panel)
            }
            .overlay(alignment: .top) {
                SettingsEditHeader(
                    isMenuOpen: Bindable(model.flow.state).prompt[.menu],
                    title: model.flow.output.isEditing ? "目標を編集" : "目標を決める",
                    isEditing: model.flow.output.isEditing,
                    isHidden: false,
                    canHide: false
                ) {
                    close()
                } onHide: {} onDelete: {
                    model.flow.state.prompt.show(.delete)
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
            .editSheet(
                model.flow,
                deleting: "この目標を削除しますか",
                note: "貯金箱の額はそのまま残ります"
            )
            .onChange(of: focus) {
                if focus != nil {
                    hidePanel()
                }
            }
            .presentationSizing(.tallForm)
    }
}

private extension AssetsRewardGoalEditSheet {
    enum Field: Hashable {
        case name
    }

    typealias Panel = AssetsRewardGoalEditModel.Panel
}

private extension AssetsRewardGoalEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 44)

            ScrollView {
                VStack(spacing: SettingsSpacing.form) {
                    AssetsRewardGoalCard(
                        name: model.state.fields.name.isEmpty ? "欲しい物" : model.state.fields.name,
                        targetAmount: model.state.calculator.amount,
                        remaining: model.output.remaining,
                        progress: model.output.progress
                    )
                    .sharesTextScale(id: model.state.fields.name)

                    SettingsField(
                        "欲しい物（例：新しい靴）",
                        text: Bindable(model.state).fields.name,
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
        PrimaryButton(model.flow.output.saveTitle) {
            save()
        }
        .disabled(!model.flow.output.canSave)
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

    func close() {
        closePanel()
        model.flow.close()
    }

    func save() {
        closePanel()
        model.flow.save()
    }
}
