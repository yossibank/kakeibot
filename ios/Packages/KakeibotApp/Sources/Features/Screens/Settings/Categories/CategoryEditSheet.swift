import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct CategoryEditSheet: View {
    @State var model: CategoryEditModel

    @FocusState var focus: Field?
    @FocusState var isTagFocused: Bool?

    @State private var layout = Layout()

    @Environment(\.themeStyle.corner) private var corner

    let startsAddingTag: Bool
    let onSave: (EntryCategory) -> Void
    let onDelete: (Deletion) -> Void
    let onHide: () -> Void

    public init(
        model: CategoryEditModel,
        startsAddingTag: Bool = false,
        onSave: @escaping (EntryCategory) -> Void = { _ in },
        onDelete: @escaping (Deletion) -> Void = { _ in },
        onHide: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: model)

        self.startsAddingTag = startsAddingTag
        self.onSave = onSave
        self.onDelete = onDelete
        self.onHide = onHide
    }

    public var body: some View {
        FloatingInputReader { _ in
            ZStack {
                content
                    .ignoresSafeArea(keyboardRegions)
                    .floatingInput(isPresented: model.state.tagEdit != nil) {
                        cancelTag()
                    } card: {
                        if let tagEdit = model.state.tagEdit {
                            tagCard(tagEdit)
                        }
                    }
            }
        }
        .iconEditorDrawer(
            model: model.state.icon,
            focus: $focus,
            textField: .text,
            below: layout.iconBottom
        )
        .errorBanner(model.state.errorNotice)
        .editSheet(
            model.flow,
            deleting: deletion,
            onHide: onHide,
            onDelete: onDelete,
            onSaved: onSave
        )
        .onChange(of: focus) {
            if focus != nil {
                model.state.setIgnoresKeyboard(false)
            }
        }
        .onOutcome(model.state.ready) { _ in
            if startsAddingTag {
                addTag()
            }
        }
        .task {
            await model.start()
        }
        .presentationSizing(.tallForm)
    }
}

extension CategoryEditSheet {
    enum Field: Hashable {
        case name
        case text
    }

    typealias TagEdit = CategoryEditModel.TagEdit
}

private extension CategoryEditSheet {
    struct Layout {
        var iconBottom: CGFloat = 0
    }
}

private extension CategoryEditSheet {
    var content: some View {
        SettingsEditForm(showsSave: focus == nil && isTagFocused == nil) {
            preview
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .global).maxY
                } action: { maxY in
                    layout.iconBottom = maxY
                }

            SettingsField(
                "名前",
                text: Bindable(model.state).fields.name,
                focus: $focus,
                field: .name
            )

            SettingsFormCard {
                tags
            }
        } save: {
            PrimaryButton(model.flow.output.saveTitle) {
                save()
            }
            .disabled(!model.flow.output.canSave)
        }
        .scrollDisabled(model.state.isMovingTag)
        .overlay(alignment: .top) {
            header
                .padding(.horizontal, SettingsSpacing.side)
                .padding(.top, SettingsSpacing.top)
        }
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
        .backdrop()
    }

    var header: some View {
        SettingsEditHeader(
            isMenuOpen: Bindable(model.flow.state).prompt[.menu],
            title: model.flow.output.isEditing ? "カテゴリを編集" : "カテゴリを追加",
            isEditing: model.flow.output.isEditing,
            isHidden: model.flow.output.isHidden,
            canDelete: !(model.flow.output.isHidden && model.input.hasEntries),
            subtitle: kindName
        ) {
            focus = nil
            model.flow.close()
        } onHide: {
            model.flow.toggleHidden()
        } onDelete: {
            model.flow.state.prompt.show(.delete)
        }
    }

    var preview: some View {
        SettingsPreviewSection(
            note: "入力シートに、アイコンと名前が並びます",
            colorNote: "色は、枠と振り返りのグラフに使います",
            dot: graphColor
        ) {
            Button {
                focus = nil
                model.state.icon.present()
            } label: {
                CategoryTileFace(
                    icon: model.state.icon.preview,
                    name: model.state.fields.name.isEmpty ? "名前" : model.state.fields.name,
                    isHidden: false
                )
                .frame(width: 80, height: 78)
                .overlay {
                    if model.state.icon.isPresented {
                        RoundedRectangle(cornerRadius: corner.radius(16))
                            .stroke(Palette.accent, lineWidth: 2)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    EditBadge()
                        .offset(x: 4, y: 4)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    var tags: some View {
        SettingsFormSection("タグ") {
            TagLine(tagItems, selection: nil) { id in
                editTag(id)
            } onAdd: {
                addTag()
            } onMove: { id, index in
                model.state.moveTag(id, to: index)
            }
            .onPreferenceChange(TagLineMovingKey.self) { isMoving in
                model.state.setMovingTag(isMoving)
            }

            if model.state.tags.count > 1 {
                SettingsCaption("長押しで並べ替えられます")
            }
        }
    }

    func tagCard(_ edit: TagEdit) -> some View {
        CategoryTagCard(
            name: tagName,
            isFocused: $isTagFocused,
            isAdding: edit.target == .add,
            errorMessage: model.state.tagProblem,
            onCommit: {
                commitTag()
            },
            onDelete: deleteAction(for: edit),
            onClose: {
                cancelTag()
            }
        )
    }
}

private extension CategoryEditSheet {
    static let hasEntriesMessage = "記録があります。非表示にすると、記録を残したまま一覧から外せます"

    var kindName: String {
        model.input.kind == .income ? "収入" : "支出"
    }

    var graphColor: Color {
        Color(hex: model.state.icon.color) ?? Palette.subtext
    }

    var deletion: SettingsConfirmation {
        guard model.input.hasEntries else {
            return .delete(
                title: "このカテゴリを削除しますか",
                message: "使っている固定費・テンプレート・予算・タグも消えます"
            )
        }

        return SettingsConfirmation(
            systemImage: "eye.slash",
            title: "このカテゴリは削除できません",
            message: Self.hasEntriesMessage,
            confirmTitle: "非表示にする",
            role: .suggestion,
            confirmsHide: true
        )
    }

    var keyboardRegions: SafeAreaRegions {
        model.state.ignoresKeyboard ? .keyboard : []
    }

    var tagName: Binding<String> {
        Binding {
            model.state.tagEdit?.name ?? ""
        } set: { name in
            model.state.inputTag(name)
        }
    }

    var tagItems: [TagLine<UUID>.Item] {
        model.state.tags.map { TagLine.Item(id: $0.id, name: $0.draft.name) }
    }

    func deleteAction(for edit: TagEdit) -> (() -> Void)? {
        guard case let .rename(id) = edit.target else {
            return nil
        }

        return {
            model.state.removeTag(id)
            closeTag()
        }
    }
}

extension CategoryEditSheet: SettingsEditSheet {
    init(
        model: CategoryEditModel,
        onDelete: @escaping (Deletion) -> Void,
        onHide: @escaping () -> Void
    ) {
        self.init(
            model: model,
            startsAddingTag: false,
            onSave: { _ in },
            onDelete: onDelete,
            onHide: onHide
        )
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        CategoryEditSheet(
            model: CategoryEditModel(
                parts: parts,
                kind: .expense
            )
        )
    }
}
