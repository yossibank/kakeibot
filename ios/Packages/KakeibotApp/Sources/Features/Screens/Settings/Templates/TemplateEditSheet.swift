import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct TemplateEditSheet: View {
    @State var model: TemplateEditModel

    @FocusState var focus: Field?

    @Environment(\.themeStyle) var themeStyle

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
            layeredContent
                .haptic(.selection, trigger: model.state.categoryId)
                .haptic(.selection, trigger: model.state.walletId)
                .editSheet(
                    model.flow,
                    deleting: "このテンプレートを削除しますか",
                    note: "このテンプレートで記録したものは残ります",
                    onHide: onHide,
                    onDelete: onDelete,
                    onSaved: onSave
                )
                .onChange(of: focus) {
                    if focus == .name {
                        hidePanel()
                    }
                }
                .sheet(
                    item: Bindable(model.state).tagCategory.item,
                    onDismiss: reloadTags
                ) { category in
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
        model.state.panel.isShowing(.memo) ? nil : model.state.panel.current
    }

    var saveButton: some View {
        PrimaryButton(model.flow.output.saveTitle) {
            closePanel()
            model.flow.save()
        }
        .disabled(!model.flow.output.canSave)
    }

    func open(_ panel: Panel) {
        focus = nil

        withAnimation(.snappy) {
            model.state.panel.show(panel)
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

            if !model.flow.output.isEditing {
                capsulePreview
            }
        } save: {
            saveButton
        }
    }

    var layeredContent: some View {
        content
            .ignoresSafeArea(keyboardRegions)
            .floatingInput(isPresented: model.state.panel.isShowing(.memo)) {
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
                    isMenuOpen: Bindable(model.flow.state).prompt[.menu],
                    title: title,
                    isEditing: model.flow.output.isEditing,
                    isHidden: model.flow.output.isHidden,
                    subtitle: model.output.typeName
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
            .errorBanner(model.state.errorNotice)
            .background {
                Backdrop()
                    .ignoresSafeArea()
                    .onTapGesture {
                        focus = nil
                    }
            }
    }
}

private extension TemplateEditSheet {
    var title: String {
        model.flow.output.isEditing ? "テンプレートを編集" : "テンプレートを追加"
    }

    var keyboardRegions: SafeAreaRegions {
        model.state.panel.isShowing(.memo) ? .keyboard : []
    }

    var memoValue: String {
        model.state.fields.memo.isEmpty ? "なし" : model.state.fields.memo
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
                isEmpty: model.state.fields.memo.isEmpty
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
            model.state.panel.closeAll()
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
