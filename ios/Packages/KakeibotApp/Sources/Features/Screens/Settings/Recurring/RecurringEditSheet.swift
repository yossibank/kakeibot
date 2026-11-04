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
    @State private var isShowingDetails = false

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
        case category
        case wallet
        case destination
        case start
        case end
        case holiday
        case closing
        case fee
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
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 44)

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.form) {
                    if !model.isEditing {
                        CapsulePicker(selection: typeBinding, options: Self.typeOptions)
                            .frame(maxWidth: .infinity)

                        RecurringPresetStrip(presets: model.presets) { preset in
                            model.apply(preset)
                        }
                        .padding(.horizontal, -4)
                    }

                    VStack(spacing: 8) {
                        RecurringRowCard(row: model.previewRow)
                            .frame(height: RecurringRowCard.height)
                            .sharesTextScale(id: model.previewRow.place)

                        SettingsPreviewNote("一覧では、このカードで並びます")
                    }

                    SettingsField(namePrompt, text: $model.memo, focus: $focus, field: .name)

                    RecurringQuickCard(model: model) { panel in
                        open(panel)
                    }

                    details

                    if model.isNotificationDenied {
                        NotificationDeniedBanner()
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 8)
                .padding(.vertical, Self.fade)
            }
            .scrollIndicators(.hidden)
            .edgeFade(Self.fade)
            .padding(.vertical, -Self.fade)
            .scrollDismissesKeyboard(.interactively)

            if panel == nil, focus == nil {
                saveButton
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: panel == nil && focus == nil)
        .padding(.horizontal, 20)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
    }

    var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.snappy) {
                    isShowingDetails.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "chevron.right")
                        .sansFont(.small)
                        .foregroundStyle(Palette.accent)
                        .rotationEffect(.degrees(isShowingDetails ? 90 : 0))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("くわしい設定")
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.accentStrong)

                        if !isShowingDetails {
                            Text(detailSummary)
                                .textFont(.caption)
                                .foregroundStyle(Palette.subtext)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if isShowingDetails {
                SettingsRowList(items: detailItems) { panel in
                    open(panel)
                }
                .transition(.opacity)
            }
        }
    }
}

private extension RecurringEditSheet {
    enum Field: Hashable {
        case name
    }

    static let fade: CGFloat = 16

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
        panel != .amount && panel != .fee
    }

    func title(for panel: Panel) -> String {
        switch panel {
        case .amount: "金額"
        case .category: "カテゴリ"
        case .wallet: model.walletTitle
        case .destination: RecurringEditModel.destinationTitle
        case .start: "始まり"
        case .end: "終わり"
        case .holiday: "休日なら"
        case .closing: "金額の決め方"
        case .fee: "手数料"
        case .remind: "前に知らせる"
        }
    }

    func open(_ panel: Panel) {
        focus = nil

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
