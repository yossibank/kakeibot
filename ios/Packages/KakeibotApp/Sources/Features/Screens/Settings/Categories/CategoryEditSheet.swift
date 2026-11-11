import Core
import DesignSystem
import Store
import SwiftUI

public struct CategoryEditSheet: View {
    @State var model: CategoryEditModel
    @State var isConfirmingDiscard = false
    @State var isConfirmingHideChanges = false
    @State var tagEdit: TagEdit?
    @State var tagName = ""
    @State var ignoresKeyboard = false

    @FocusState var focus: Field?
    @FocusState var isTagFocused: Bool?

    @Environment(\.dismiss) var dismiss

    @State private var isConfirmingDelete = false
    @State private var isMovingTag = false
    @State private var isEditingIcon = false
    @State private var iconBottom: CGFloat = 0

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
        GeometryReader { _ in
            ZStack {
                content
                    .ignoresSafeArea(keyboardRegions)
                    .floatingInput(isPresented: tagEdit != nil) {
                        cancelTag()
                    } card: {
                        if let tagEdit {
                            tagCard(tagEdit)
                        }
                    }
            }
        }
        .iconEditorDrawer(
            isPresented: $isEditingIcon,
            model: model.icon,
            focus: $focus,
            textField: .text,
            below: iconBottom
        )
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
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
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
        }
        .confirmation(
            isPresented: $isConfirmingDelete,
            systemImage: deleteImage,
            title: deleteTitle,
            message: deleteMessage,
            keepTitle: "やめる",
            confirmTitle: deleteConfirmTitle,
            role: deleteRole
        ) {
            if model.hasEntries {
                toggleHidden()
            } else {
                Task {
                    await delete()
                }
            }
        }
        .onChange(of: focus) {
            if focus != nil {
                ignoresKeyboard = false
            }
        }
        .task {
            await model.load()

            if startsAddingTag {
                addTag()
            }
        }
    }
}

extension CategoryEditSheet {
    enum Field: Hashable {
        case name
        case text
    }

    enum TagEdit: Hashable {
        case add
        case rename(UUID)
    }
}

private extension CategoryEditSheet {
    var content: some View {
        SettingsEditForm(showsSave: focus == nil && isTagFocused == nil) {
            preview
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .global).maxY
                } action: { maxY in
                    iconBottom = maxY
                }

            SettingsField(
                "名前",
                text: $model.name,
                focus: $focus,
                field: .name
            )

            SettingsFormCard {
                tags
            }
        } save: {
            PrimaryButton(model.saveTitle) {
                Task {
                    await save()
                }
            }
            .disabled(!model.canSave)
        }
        .scrollDisabled(isMovingTag)
        .overlay(alignment: .top) {
            header
                .padding(.horizontal, 20)
                .padding(.top, SettingsSpacing.top)
        }
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
    }

    var header: some View {
        SettingsEditHeader(
            title: model.isEditing ? "カテゴリを編集" : "カテゴリを追加",
            isEditing: model.isEditing,
            isHidden: model.isHidden,
            canDelete: !(model.isHidden && model.hasEntries),
            subtitle: kindName
        ) {
            close()
        } onHide: {
            toggleHidden()
        } onDelete: {
            isConfirmingDelete = true
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
                isEditingIcon = true
            } label: {
                CategoryTileFace(
                    icon: model.icon.preview,
                    name: model.name.isEmpty ? "名前" : model.name,
                    isHidden: false
                )
                .frame(width: 80, height: 78)
                .overlay {
                    if isEditingIcon {
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
                model.moveTag(id, to: index)
            }
            .onPreferenceChange(TagLineMovingKey.self) { isMoving in
                isMovingTag = isMoving
            }

            if model.tags.count > 1 {
                SettingsCaption("長押しで並べ替えられます")
            }
        }
    }

    func tagCard(_ edit: TagEdit) -> some View {
        CategoryTagCard(
            name: $tagName,
            isFocused: $isTagFocused,
            isAdding: edit == .add,
            errorMessage: model.tagProblem,
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
        model.kind == .income ? "収入" : "支出"
    }

    var graphColor: Color {
        Color(hex: model.icon.color) ?? Palette.subtext
    }

    var deleteImage: String {
        model.hasEntries ? "eye.slash" : "trash"
    }

    var deleteTitle: String {
        model.hasEntries ? "このカテゴリは削除できません" : "このカテゴリを削除しますか"
    }

    var deleteMessage: String {
        model.hasEntries ? Self.hasEntriesMessage : "使っている固定費・テンプレート・予算・タグも消えます"
    }

    var deleteConfirmTitle: String {
        model.hasEntries ? "非表示にする" : "削除する"
    }

    var deleteRole: ConfirmCard.Role {
        model.hasEntries ? .suggestion : .destructive
    }

    var keyboardRegions: SafeAreaRegions {
        ignoresKeyboard ? .keyboard : []
    }

    var tagItems: [TagLine<UUID>.Item] {
        model.tags.map { TagLine.Item(id: $0.id, name: $0.draft.name) }
    }

    func deleteAction(for edit: TagEdit) -> (() -> Void)? {
        guard case let .rename(id) = edit else {
            return nil
        }

        return {
            model.removeTag(id)
            closeTag()
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        CategoryEditSheet(
            model: CategoryEditModel(
                database: database,
                kind: .expense
            )
        )
    }
}
