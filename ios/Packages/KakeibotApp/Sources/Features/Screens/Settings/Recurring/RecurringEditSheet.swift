import Core
import DesignSystem
import Store
import SwiftUI

public struct RecurringEditSheet: View {
    @State var model: RecurringEditModel

    @State private var panel: Panel?
    @State private var prompt = SettingsEditPrompt()
    @State private var isConfirmingDelete = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss
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
            .settingsDrawerLayer(item: panel) {
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
                    title: headerTitle,
                    isEditing: model.isEditing,
                    isHidden: model.input.isHidden
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
            .errorBanner(Bindable(model.state).errorNotice)
            .background {
                Backdrop()
                    .ignoresSafeArea()
                    .onTapGesture {
                        focus = nil
                    }
            }
            .settingsEditConfirmations(edit)
            .confirmation(
                isPresented: $isConfirmingDelete,
                systemImage: "trash",
                title: "この固定費を削除しますか",
                message: "これまでに作った記録は残ります",
                keepTitle: "やめる",
                confirmTitle: "削除する"
            ) {
                Task {
                    await edit.delete()
                }
            }
            .animation(.snappy, value: model.output.isNotificationDenied)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task {
                        await model.refreshAuthorization(permission)
                    }
                }
            }
            .task {
                await model.load()
                await model.refreshAuthorization(permission)
            }
            .presentationSizing(.tallForm)
    }
}

extension RecurringEditSheet {
    var saveButton: some View {
        PrimaryButton(model.saveTitle) {
            Task {
                await edit.save()
            }
        }
        .disabled(!model.canSave)
    }
}

extension RecurringEditSheet {
    enum Panel: Hashable {
        case amount
        case start
        case end
        case holiday
        case closing
        case fee
        case count
        case remind
    }

    func closePanel() {
        withAnimation(.snappy) {
            panel = nil
        }
    }
}

private extension RecurringEditSheet {
    var content: some View {
        SettingsEditForm(showsSave: focus == nil) {
            if !model.isEditing {
                CapsulePicker(selection: typeBinding, options: Self.typeOptions)
                    .frame(maxWidth: .infinity)
            }

            SettingsPreviewSection(note: "一覧では、このカードで並びます") {
                RecurringRowCard(row: model.output.previewRow)
                    .frame(height: RecurringRowCard.height)
                    .sharesTextScale(id: model.output.previewRow.place)
            }

            SettingsField(namePrompt, text: Bindable(model.state).memo, focus: $focus, field: .name)

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
                        model.useAutoCount()
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
    enum Field: Hashable {
        case name
    }

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
        model.isEditing ? "固定費を編集" : "固定費を追加"
    }

    var typeBinding: Binding<Entry.Kind> {
        Binding {
            model.state.type
        } set: { type in
            model.select(type)
        }
    }

    var edit: SettingsEditController<RecurringEditModel> {
        SettingsEditController(
            model: model,
            prompt: $prompt,
            dismiss: dismiss,
            onRest: {
                closePanel()
            },
            onHide: onHide,
            onDelete: onDelete,
            onSave: {
                await model.save(permission: permission)
            }
        )
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
            self.panel = panel
        }
    }
}

extension RecurringEditModel: SettingsEditing {}

extension RecurringEditSheet: SettingsEditSheet {}
