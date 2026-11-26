import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct TemplateEditSheet: View {
    @State var model: TemplateEditModel

    @FocusState var focus: Field?

    @Environment(\.themeStyle) var themeStyle

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
                .floatingInput(isPresented: model.state.prompt.panel == .memo) {
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
                        isMenuOpen: Bindable(model.state).prompt.isMenuOpen,
                        title: title,
                        isEditing: model.isEditing,
                        isHidden: model.input.isHidden,
                        subtitle: model.output.typeName
                    ) {
                        edit.close()
                    } onHide: {
                        edit.toggleHidden()
                    } onDelete: {
                        model.state.prompt.isConfirmingDelete = true
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
                .haptic(.selection, trigger: model.state.categoryId)
                .haptic(.selection, trigger: model.state.walletId)
                .settingsEditConfirmations(edit)
                .confirmation(
                    isPresented: Bindable(model.state).prompt.isConfirmingDelete,
                    systemImage: "trash",
                    title: "このテンプレートを削除しますか",
                    message: "このテンプレートで記録したものは残ります",
                    keepTitle: "やめる",
                    confirmTitle: "削除する"
                ) {
                    edit.delete()
                }
                .onChange(of: focus) {
                    if focus == .name {
                        hidePanel()
                    }
                }
                .sheet(item: Bindable(model.state).tagCategory, onDismiss: reloadTags) { category in
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
    enum Field: Hashable {
        case name
        case memo
    }

    typealias Panel = TemplateEditModel.Panel
}

extension TemplateEditSheet {
    var drawerPanel: Panel? {
        model.state.prompt.panel == .memo ? nil : model.state.prompt.panel
    }

    var edit: SettingsEditController<TemplateEditModel> {
        SettingsEditController(
            model: model,
            dismiss: dismiss,
            onRest: {
                closePanel()
            },
            onHide: onHide,
            onDelete: onDelete,
            onSaved: onSave,
            onSave: {
                await $0.save()
            }
        )
    }

    var saveButton: some View {
        PrimaryButton(model.saveTitle) {
            edit.save()
        }
        .disabled(!model.canSave)
    }

    func open(_ panel: Panel) {
        focus = nil

        withAnimation(.snappy) {
            model.state.open(panel)
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
        model.state.prompt.panel == .memo ? .keyboard : []
    }

    var memoValue: String {
        model.state.memo.isEmpty ? "なし" : model.state.memo
    }

    var detailItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .tag,
                systemImage: "tag",
                title: "タグ",
                value: model.output.selectedTag?.name ?? "なし",
                isEmpty: model.output.selectedTag == nil
            ),
            .init(
                panel: .memo,
                systemImage: "square.and.pencil",
                title: "メモ",
                value: memoValue,
                isEmpty: model.state.memo.isEmpty
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
        model.perform {
            await $0.reloadTags()
        }
    }

    func hidePanel() {
        withAnimation(.snappy) {
            model.state.closePanel()
        }
    }
}

extension TemplateEditSheet: SettingsEditSheet {
    init(
        model: TemplateEditModel,
        onDelete: @escaping (Deletion) -> Void,
        onHide: @escaping () -> Void
    ) {
        self.init(
            model: model,
            onSave: { _ in },
            onDelete: onDelete,
            onHide: onHide
        )
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        TemplateEditSheet(
            model: TemplateEditModel(
                parts: parts,
                type: .expense
            )
        )
    }
}
