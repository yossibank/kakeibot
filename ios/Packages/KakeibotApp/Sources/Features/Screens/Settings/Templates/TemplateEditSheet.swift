import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateEditSheet: View {
    @State var model: TemplateEditModel

    @FocusState var focus: Field?

    @Environment(\.themeStyle) var themeStyle

    @State private var panel: Panel?
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingHideChanges = false
    @State private var isConfirmingDelete = false

    @Environment(\.dismiss) private var dismiss

    let onSave: (EntryTemplate) -> Void
    let onDelete: (Deletion) -> Void
    let onHide: () -> Void

    public init(
        model: TemplateEditModel,
        onSave: @escaping (EntryTemplate) -> Void = { _ in },
        onDelete: @escaping (Deletion) -> Void = { _ in },
        onHide: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: model)

        self.onSave = onSave
        self.onDelete = onDelete
        self.onHide = onHide
    }

    public var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                content
                    .ignoresSafeArea(keyboardRegions)

                if let panel {
                    Palette.scrim
                        .opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closePanel()
                        }
                        .transition(.opacity)
                        .zIndex(1)

                    if panel == .memo {
                        memoCard
                            .padding(.horizontal, 16)
                            .frame(maxHeight: .infinity)
                            .transition(Self.memoTransition)
                            .zIndex(1)
                    } else {
                        SettingsDrawer(title(for: panel), showsDone: showsDone(for: panel)) {
                            closePanel()
                        } content: {
                            drawerBody(panel)
                        }
                        .transition(.settingsDrawer)
                        .zIndex(1)
                    }
                }
            }
            .overlay(alignment: .top) {
                SettingsEditHeader(
                    title: title,
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
                .padding(.top, 20)
            }
            .errorBanner(model.errorNotice) {
                model.errorNotice.clear()
            }
            .background {
                Rectangle()
                    .fill(Palette.background)
                    .ignoresSafeArea()
                    .onTapGesture {
                        focus = nil
                    }
            }
            .sensoryFeedback(.selection, trigger: model.categoryId)
            .sensoryFeedback(.selection, trigger: model.walletId)
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
                title: "このテンプレートを削除しますか",
                message: "このテンプレートで記録したものは残ります",
                keepTitle: "やめる",
                confirmTitle: "削除する"
            ) {
                Task {
                    await delete()
                }
            }
            .onChange(of: focus) {
                if focus == .name {
                    hidePanel()
                }
            }
            .task {
                await model.load()
            }
        }
    }
}

extension TemplateEditSheet {
    var saveButton: some View {
        PrimaryButton(model.saveTitle) {
            Task {
                await save()
            }
        }
        .disabled(!model.canSave)
    }
}

extension TemplateEditSheet {
    enum Field: Hashable {
        case name
        case memo
    }

    enum Panel: Hashable {
        case amount
        case category
        case tag
        case wallet
        case memo
    }

    func open(_ panel: Panel) {
        focus = nil

        withAnimation(.snappy) {
            self.panel = panel
        }
    }

    func closePanel() {
        focus = nil
        hidePanel()
    }
}

private extension TemplateEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 44)

            ScrollView {
                VStack(spacing: 16) {
                    preview

                    VStack(alignment: .leading, spacing: 8) {
                        SettingsRowList(items: rowItems) { panel in
                            open(panel)
                        }

                        Text("金額を空にすると、使うときに入れられます")
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                            .padding(.leading, 8)
                    }

                    if !model.isEditing {
                        capsulePreview
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .contentMargins(.vertical, Self.fade, for: .scrollContent)
            .edgeFade(Self.fade)
            .padding(.horizontal, -20)

            saveButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

private extension TemplateEditSheet {
    static let fade: CGFloat = 16

    static var memoTransition: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }

    var title: String {
        let action = model.isEditing ? "編集" : "追加"

        return "\(model.typeName)テンプレートを\(action)"
    }

    var keyboardRegions: SafeAreaRegions {
        panel == .memo ? .keyboard : []
    }

    var memoValue: String {
        model.memo.isEmpty ? "なし" : model.memo
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
            ),
            .init(
                panel: .category,
                systemImage: "square.grid.2x2",
                title: "カテゴリ",
                value: model.selectedCategory?.name ?? "選ぶ",
                isEmpty: model.selectedCategory == nil
            ),
            .init(
                panel: .tag,
                systemImage: "tag",
                title: "タグ",
                value: model.selectedTag?.name ?? "なし",
                isEmpty: model.selectedTag == nil
            ),
            .init(
                panel: .wallet,
                systemImage: "wallet.bifold",
                title: model.walletTitle,
                value: model.selectedWallet?.name ?? "選ぶ",
                isEmpty: model.selectedWallet == nil
            ),
            .init(
                panel: .memo,
                systemImage: "square.and.pencil",
                title: "メモ",
                value: memoValue,
                isEmpty: model.memo.isEmpty
            )
        ]
    }

    func showsDone(for panel: Panel) -> Bool {
        panel != .amount
    }

    func title(for panel: Panel) -> String {
        switch panel {
        case .amount: "金額"
        case .category: "カテゴリ"
        case .tag: "タグ"
        case .wallet: model.walletTitle
        case .memo: "メモ"
        }
    }

    func hidePanel() {
        withAnimation(.snappy) {
            panel = nil
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

        guard let template = await model.save() else {
            return
        }

        onSave(template)

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

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        TemplateEditSheet(
            model: TemplateEditModel(
                database: database,
                type: .expense
            )
        )
    }
}
