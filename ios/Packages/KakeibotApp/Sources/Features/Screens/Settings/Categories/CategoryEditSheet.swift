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
            systemImage: "trash",
            title: "このカテゴリを削除しますか",
            message: "使っている固定費・テンプレート・予算・タグも消えます",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            Task {
                await delete()
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
        VStack(spacing: 16) {
            header

            ScrollView {
                VStack(spacing: 16) {
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

                    tags
                }
                .padding(.bottom, 8)
                .padding(.vertical, Self.fade)
            }
            .scrollIndicators(.hidden)
            .edgeFade(Self.fade)
            .padding(.vertical, -Self.fade)
            .scrollDismissesKeyboard(.interactively)
            .scrollDisabled(isMovingTag)

            PrimaryButton(model.saveTitle) {
                Task {
                    await save()
                }
            }
            .disabled(!model.canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
    }

    var header: some View {
        SettingsEditHeader(
            title: model.isEditing ? "カテゴリを編集" : "カテゴリを追加",
            isEditing: model.isEditing,
            isHidden: model.isHidden
        ) {
            close()
        } onHide: {
            toggleHidden()
        } onDelete: {
            isConfirmingDelete = true
        }
    }

    var preview: some View {
        HStack(spacing: 20) {
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

            VStack(alignment: .leading, spacing: 8) {
                Text("入力シートでの見え方")

                HStack(spacing: 8) {
                    Circle()
                        .fill(graphColor)
                        .frame(width: 10, height: 10)

                    Text("振り返りのグラフの色")
                }
            }
            .textFont(.caption2)
            .foregroundStyle(Palette.subtext)
        }
    }

    var tags: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                SectionTitle("タグ")

                Spacer()

                if model.tags.count > 1 {
                    Text("長押しで並べ替え")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
            }

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
            .onChange(of: isMovingTag) {
                if !isMovingTag {
                    storeTags()
                }
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
    static let fade: CGFloat = 16

    var graphColor: Color {
        Color(hex: model.icon.color) ?? Palette.subtext
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
            storeTags()
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
