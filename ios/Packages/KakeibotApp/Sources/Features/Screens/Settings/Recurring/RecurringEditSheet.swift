import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct RecurringEditSheet: View {
    @State var model: RecurringEditModel

    @FocusState private var focus: Field?

    @Environment(\.notificationPermission) private var permission
    @Environment(\.scenePhase) private var scenePhase

    private let onDelete: (Deletion) -> Void
    private let onHide: () -> Void

    public init(
        model: RecurringEditModel,
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
                SettingsDrawer(title(for: panel), showsDone: showsDone(for: panel)) {
                    closePanel()
                } content: {
                    drawerBody(panel)
                }
            }
            .overlay(alignment: .top) {
                SettingsEditHeader(
                    isMenuOpen: Bindable(model.flow.state).prompt[.menu],
                    title: headerTitle,
                    isEditing: model.flow.output.isEditing,
                    isHidden: model.flow.output.isHidden
                ) {
                    closePanel()
                    model.flow.close()
                } onHide: {
                    model.flow.toggleHidden()
                } onDelete: {
                    model.flow.state.prompt.show(.delete)
                }
                .padding(.horizontal, SettingsSpacing.side)
                .padding(.top, SettingsSpacing.top)
            }
            .errorBanner(Bindable(model.state).errorNotice)
            .background {
                Backdrop()
                    .ignoresSafeArea()
                    .onTapGesture {
                        focus = nil
                    }
            }
            .editSheet(
                model.flow,
                deleting: "この固定費を削除しますか",
                note: "これまでに作った記録は残ります",
                onHide: onHide,
                onDelete: onDelete
            )
            .animation(.snappy, value: model.output.isNotificationDenied)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    model.perform {
                        await $0.refreshAuthorization(permission)
                    }
                }
            }
            .task {
                await model.refreshAuthorization(permission)
                await model.load()
            }
            .presentationSizing(.tallForm)
    }
}

extension RecurringEditSheet {
    typealias Panel = RecurringEditModel.Panel
}

private extension RecurringEditSheet {
    enum Field: Hashable {
        case name
    }
}

extension RecurringEditSheet {
    var saveButton: some View {
        PrimaryButton(model.flow.output.saveTitle) {
            closePanel()
            model.flow.save()
        }
        .disabled(!model.flow.output.canSave)
    }

    func closePanel() {
        withAnimation(.snappy) {
            model.state.panel.closeAll()
        }
    }
}

private extension RecurringEditSheet {
    var content: some View {
        SettingsEditForm(showsSave: focus == nil) {
            if !model.flow.output.isEditing {
                CapsulePicker(selection: typeBinding, options: Self.typeOptions)
                    .frame(maxWidth: .infinity)
            }

            SettingsPreviewSection(note: "一覧では、このカードで並びます") {
                RecurringRowCard(row: model.output.previewRow)
                    .frame(height: RecurringRowCard.height)
                    .sharesTextScale(id: model.output.previewRow.place)
            }

            SettingsField(
                namePrompt,
                text: Bindable(model.state).fields.memo,
                focus: $focus,
                field: .name
            )

            RecurringQuickCard(model: model) { panel in
                open(panel)
            }

            SettingsDetails {
                SettingsRowList(items: detailItems) { panel in
                    open(panel)
                }
            }

            if model.output.isLoanRepayment,
               model.output.plannedTotal != nil || model.output.autoPlan != nil {
                RecurringLoanPlan(model: model) {
                    withAnimation(.snappy) {
                        model.state.repayment.useAutoCount()
                    }
                }
                .transition(.opacity)
            }

            if model.output.isNotificationDenied {
                NotificationDeniedBanner()
                    .transition(.opacity)
            }
        } save: {
            saveButton
        }
    }
}

private extension RecurringEditSheet {
    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income),
        .init("振替", value: .transfer)
    ]

    var namePrompt: String {
        switch model.state.type {
        case .expense: "家賃・サブスクなど"
        case .income: "給料・年金など"
        case .transfer: "カードの引き落とし・積立など"
        }
    }

    var headerTitle: String {
        model.flow.output.isEditing ? "固定費を編集" : "固定費を追加"
    }

    var typeBinding: Binding<Entry.Kind> {
        Binding {
            model.state.type
        } set: { type in
            model.select(type)
        }
    }

    func showsDone(for panel: Panel) -> Bool {
        ![.amount, .fee, .count].contains(panel)
    }

    func title(for panel: Panel) -> String {
        switch panel {
        case .amount: "金額"
        case .start: "始まり"
        case .end: "終わり"
        case .holiday: "休日なら"
        case .closing: "金額の決め方"
        case .fee: "手数料"
        case .count: "回数"
        case .remind: "前に知らせる"
        }
    }

    func open(_ panel: Panel) {
        focus = nil

        if panel == .count {
            model.prepareCount()
        }

        withAnimation(.snappy) {
            model.state.panel.show(panel)
        }
    }
}

extension RecurringEditSheet: SettingsEditSheet {}
