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
    @State private var prompt = SettingsEditPrompt()
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
        FloatingInputReader { _ in
            content
                .ignoresSafeArea(keyboardRegions)
                .floatingInput(isPresented: panel == .memo) {
                    closePanel()
                } card: {
                    memoCard
                }
                .settingsDrawerLayer(item: drawerPanel) {
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
                        title: title,
                        isEditing: model.isEditing,
                        isHidden: model.isHidden,
                        subtitle: model.typeName
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
                .errorBanner($model.errorNotice)
                .background {
                    Backdrop()
                        .ignoresSafeArea()
                        .onTapGesture {
                            focus = nil
                        }
                }
                .haptic(.selection, trigger: model.categoryId)
                .haptic(.selection, trigger: model.walletId)
                .settingsEditConfirmations(edit)
                .confirmation(
                    isPresented: $isConfirmingDelete,
                    systemImage: "trash",
                    title: "このテンプレートを削除しますか",
                    message: "このテンプレートで記録したものは残ります",
                    keepTitle: "やめる",
                    confirmTitle: "削除する"
                ) {
                    Task {
                        await edit.delete()
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
                await edit.save()
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

    var drawerPanel: Panel? {
        panel == .memo ? nil : panel
    }

    var edit: SettingsEditController<TemplateEditModel> {
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
                guard let template = await model.save() else {
                    return false
                }

                onSave(template)
                return true
            }
        )
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
        model.isEditing ? "テンプレートを編集" : "テンプレートを追加"
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
}

extension TemplateEditModel: SettingsEditing {}

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
