import Core
import DesignSystem
import Store
import SwiftUI

public struct RecurringEditSheet: View {
    @State var model: RecurringEditModel

    @State private var panel: Panel?
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingHideChanges = false
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

                SettingsDrawer(title(for: panel), showsDone: showsDone(for: panel)) {
                    closePanel()
                } content: {
                    drawerBody(panel)
                }
                .transition(.settingsDrawer)
                .zIndex(1)
            }
        }
        .overlay(alignment: .top) {
            SettingsEditHeader(
                title: headerTitle,
                isEditing: model.isEditing,
                isHidden: model.isHidden
            ) {
                close()
            } onHide: {
                toggleHidden()
            } onDelete: {
                isConfirmingDelete = true
            }
            .padding(.horizontal, 20)
            .padding(.top, SettingsSpacing.top)
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
                .onTapGesture {
                    focus = nil
                }
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
        .confirmsDiscard(when: model.isChanged, isPresented: $isConfirmingDiscard) {
            dismiss()
        }
        .confirmation(
            isPresented: $isConfirmingDelete,
            systemImage: "trash",
            title: "この固定費を削除しますか",
            message: "これまでに作った記録は残ります",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            Task {
                await delete()
            }
        }
        .animation(.snappy, value: model.isNotificationDenied)
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
    }
}

extension RecurringEditSheet {
    var saveButton: some View {
        PrimaryButton(model.saveTitle) {
            Task {
                await save()
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
        case finalAmount
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
                RecurringRowCard(row: model.previewRow)
                    .frame(height: RecurringRowCard.height)
                    .sharesTextScale(id: model.previewRow.place)
            }

            SettingsField(namePrompt, text: $model.memo, focus: $focus, field: .name)

            RecurringQuickCard(model: model) { panel in
                open(panel)
            }

            SettingsDetails {
                SettingsRowList(items: detailItems) { panel in
                    open(panel)
                }
            }

            if model.isLoanRepayment,
               let total = model.plannedTotal,
               let end = model.endDate {
                RecurringLoanPlan(total: total, endDate: end)
                    .transition(.opacity)
            }

            if model.isNotificationDenied {
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
        switch model.type {
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
            model.type
        } set: { type in
            model.select(type)
        }
    }

    func showsDone(for panel: Panel) -> Bool {
        ![.amount, .fee, .count, .finalAmount].contains(panel)
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
        case .finalAmount: "最終回の額"
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

        if await model.save(permission: permission) {
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

    func delete() async {
        if let deletion = await model.delete() {
            onDelete(deletion)
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
        if await model.setHidden(isHidden) {
            if isHidden {
                onHide()
            }

            dismiss()
        }
    }
}
