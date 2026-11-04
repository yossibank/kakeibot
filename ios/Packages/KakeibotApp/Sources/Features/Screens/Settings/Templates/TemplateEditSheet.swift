import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateEditSheet: View {
    @State var model: TemplateEditModel
    @State var tagCategory: EntryCategory?

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
                    .floatingInput(isPresented: panel == .memo) {
                        closePanel()
                    } card: {
                        memoCard
                    }

                if let panel,
                   panel != .memo {
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
            .haptic(.selection, trigger: model.categoryId)
            .haptic(.selection, trigger: model.walletId)
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
            .sheet(item: $tagCategory, onDismiss: reloadTags) { category in
                CategoryEditSheet(
                    model: model.editCategoryModel(category),
                    startsAddingTag: true
                )
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
        case tag
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
        SettingsEditForm(showsSave: focus != .name) {
            preview

            TemplateQuickCard(model: model) { panel in
                open(panel)
            }

            SettingsDetails {
                SettingsRowList(items: detailItems) { panel in
                    open(panel)
                }
            }

            if !model.isEditing {
                capsulePreview
            }
        } save: {
            saveButton
        }
    }
}

private extension TemplateEditSheet {
    var title: String {
        let action = model.isEditing ? "編集" : "追加"
        return "\(model.typeName)のテンプレートを\(action)"
    }

    var keyboardRegions: SafeAreaRegions {
        panel == .memo ? .keyboard : []
    }

    var memoValue: String {
        model.memo.isEmpty ? "なし" : model.memo
    }

    var detailItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .tag,
                systemImage: "tag",
                title: "タグ",
                value: model.selectedTag?.name ?? "なし",
                isEmpty: model.selectedTag == nil
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
        case .tag: "タグ"
        case .memo: "メモ"
        }
    }

    func reloadTags() {
        Task {
            await model.reloadTags()
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
