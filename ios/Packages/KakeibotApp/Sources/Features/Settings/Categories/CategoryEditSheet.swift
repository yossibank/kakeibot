import Core
import DesignSystem
import Store
import SwiftUI

public struct CategoryEditSheet: View {
    @State private var model: CategoryEditModel
    @State private var isConfirmingDiscard = false
    @State private var tagEdit: TagEdit?
    @State private var isMovingTag = false
    @State private var tagName = ""
    @State private var ignoresKeyboard = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let startsAddingTag: Bool
    let onSave: (EntryCategory) -> Void

    public init(
        model: CategoryEditModel,
        startsAddingTag: Bool = false,
        onSave: @escaping (EntryCategory) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        self.startsAddingTag = startsAddingTag
        self.onSave = onSave
    }

    public var body: some View {
        GeometryReader { _ in
            ZStack {
                content
                    .ignoresSafeArea(keyboardRegions)

                if let tagEdit {
                    tagLayer(tagEdit)
                }
            }
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
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

private extension CategoryEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    preview

                    SettingsField(
                        "名前",
                        text: $model.name,
                        focus: $focus,
                        field: .name
                    )

                    tags

                    IconEditor(
                        model: model.icon,
                        focus: $focus,
                        textField: .text
                    )
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
        .padding(.horizontal, 18)
        .padding(.top, 18)
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
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }

            Spacer()

            Text(model.isEditing ? "カテゴリを編集" : "カテゴリを追加")
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            if model.isEditing {
                SettingsHideButton(isHidden: model.isHidden) {
                    Task {
                        await setHidden(!model.isHidden)
                    }
                }
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }

    var preview: some View {
        HStack(spacing: 18) {
            VStack(spacing: 6) {
                IconImage(model.icon.preview, size: 24)
                    .foregroundStyle(Palette.accent)

                Text(model.name.isEmpty ? "名前" : model.name)
                    .textFont(size: .caption)
                    .lineLimit(1)
            }
            .foregroundStyle(Palette.accentStrong)
            .frame(width: 86, height: 86)
            .background(
                Palette.accent.opacity(.subtle),
                in: .rect(cornerRadius: corner.radius(18))
            )
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(18))
                    .stroke(Palette.outline, lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("入力シートでの見え方")

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: model.icon.color) ?? Palette.subtext)
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
                SettingsSectionTitle("タグ")

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
        }
    }

    @ViewBuilder
    func tagLayer(_ edit: TagEdit) -> some View {
        Palette.scrim
            .opacity(0.45)
            .ignoresSafeArea()
            .onTapGesture {
                closeTag()
            }
            .transition(.opacity)

        CategoryTagCard(
            name: $tagName,
            isAdding: edit == .add,
            errorMessage: model.tagProblem,
            onCommit: {
                commitTag()
            },
            onDelete: deleteAction(for: edit),
            onClose: {
                closeTag()
            }
        )
        .padding(.horizontal, 20)
        .transition(Self.tagTransition)
    }
}

private extension CategoryEditSheet {
    enum Field: Hashable {
        case name
        case text
    }

    enum TagEdit: Hashable {
        case add
        case rename(UUID)
    }

    static let fade: CGFloat = 16

    var keyboardRegions: SafeAreaRegions {
        ignoresKeyboard ? .keyboard : []
    }

    var tagItems: [TagLine<UUID>.Item] {
        model.tags.map { TagLine.Item(id: $0.id, name: $0.draft.name) }
    }

    static var tagTransition: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
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

    func addTag() {
        showTag(.add, name: "")
    }

    func editTag(_ id: UUID) {
        let name = model.tags.first { $0.id == id }?.draft.name ?? ""
        showTag(.rename(id), name: name)
    }

    func showTag(
        _ edit: TagEdit,
        name: String
    ) {
        focus = nil
        tagName = name
        ignoresKeyboard = true
        model.clearTagProblem()

        withAnimation(.snappy(duration: 0.25)) {
            tagEdit = edit
        }
    }

    func closeTag() {
        model.clearTagProblem()

        withAnimation(.snappy(duration: 0.2)) {
            tagEdit = nil
        }
    }

    func commitTag() {
        let isDone = switch tagEdit {
        case .add: model.addTag(tagName)
        case let .rename(id): model.renameTag(id, to: tagName)
        case nil: true
        }

        if isDone {
            closeTag()
        }
    }

    func close() {
        focus = nil

        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save() async {
        focus = nil

        guard let category = await model.save() else {
            return
        }

        onSave(category)
        dismiss()
    }

    func setHidden(_ isHidden: Bool) async {
        if await model.setHidden(isHidden) {
            dismiss()
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        CategoryEditSheet(
            model: CategoryEditModel(database: database, kind: .expense)
        )
    }
}
