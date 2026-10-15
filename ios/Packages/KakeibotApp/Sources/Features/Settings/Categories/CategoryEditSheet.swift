import Core
import DesignSystem
import Store
import SwiftUI

public struct CategoryEditSheet: View {
    @State private var model: CategoryEditModel
    @State private var isConfirmingDiscard = false
    @State private var tagEdit: TagEdit?
    @State private var tagName = ""

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

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
                    .ignoresSafeArea(.keyboard)

                if let tagEdit {
                    tagLayer(tagEdit)
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
        }
        .onChange(of: model.markKind) {
            focus = nil
        }
        .onChange(of: model.glyph) {
            focus = nil
        }
        .onChange(of: model.emoji) {
            focus = nil
        }
        .onChange(of: model.color) {
            focus = nil
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
            preview
            field("名前", text: $model.name, font: .body, focus: .name)
            tags
            colors
            CapsulePicker(selection: $model.markKind, options: Self.markOptions)

            ScrollView {
                markChooser
                    .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.rose)
            }

            if model.isEditing {
                hideButton
            }
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
                .fill(Palette.night)
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
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Button("保存") {
                Task {
                    await save()
                }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(saveColor)
            .frame(minWidth: 44, minHeight: 44)
            .disabled(!model.canSave)
        }
    }

    var preview: some View {
        HStack(spacing: 18) {
            VStack(spacing: 6) {
                IconImage(model.preview, size: 24)
                    .foregroundStyle(Palette.gold)

                Text(model.name.isEmpty ? "名前" : model.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            .foregroundStyle(Palette.champagne)
            .frame(width: 86, height: 86)
            .background(Palette.gold.opacity(0.12), in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Palette.gold.opacity(0.55), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("入力シートでの見え方")

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: model.color) ?? Palette.mist)
                        .frame(width: 10, height: 10)

                    Text("振り返りのグラフの色")
                }
            }
            .font(.caption2)
            .foregroundStyle(Palette.mist)
        }
    }

    var tags: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionTitle("タグ")

            TagLine(tagItems, selection: nil) { index in
                editTag(at: index)
            } onAdd: {
                addTag()
            }
        }
    }

    @ViewBuilder
    func tagLayer(_ edit: TagEdit) -> some View {
        Color.black
            .opacity(0.45)
            .ignoresSafeArea()
            .onTapGesture {
                closeTag()
            }
            .transition(.opacity)

        CategoryTagCard(
            name: $tagName,
            isAdding: edit == .add,
            errorMessage: model.errorMessage,
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

    var colors: some View {
        LazyVGrid(columns: Self.colorColumns, spacing: 4) {
            ForEach(CategoryEditModel.colors, id: \.self) { hex in
                colorButton(hex)
            }

            ColorPicker(
                "ほかの色",
                selection: customColor,
                supportsOpacity: false
            )
            .labelsHidden()
            .frame(width: 30, height: 30)
        }
    }

    @ViewBuilder
    var markChooser: some View {
        switch model.markKind {
        case .glyph:
            glyphChooser
        case .emoji:
            emojiChooser
        case .text:
            textChooser
        }
    }

    var glyphChooser: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(CategoryEditModel.glyphSections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    sectionTitle(section.title)

                    LazyVGrid(columns: Self.gridColumns, spacing: 6) {
                        ForEach(section.glyphs, id: \.self) { glyph in
                            glyphButton(glyph)
                        }
                    }
                }
            }
        }
    }

    var emojiChooser: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(CategoryEditModel.emojiSections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    sectionTitle(section.title)

                    LazyVGrid(columns: Self.gridColumns, spacing: 6) {
                        ForEach(section.emojis, id: \.self) { emoji in
                            emojiButton(emoji)
                        }
                    }
                }
            }
        }
    }

    var textChooser: some View {
        VStack(alignment: .leading, spacing: 8) {
            field(
                "3 文字まで",
                text: textBinding,
                font: .system(size: 20, design: .serif),
                focus: .text
            )

            Text("「外」「推し」のように、短い文字をアイコンにする")
                .font(.caption)
                .foregroundStyle(Palette.mist)
        }
    }

    var hideButton: some View {
        Button {
            Task {
                await setHidden(!model.isHidden)
            }
        } label: {
            Text(model.isHidden ? "表示に戻す" : "このカテゴリを非表示にする")
                .font(.subheadline)
                .foregroundStyle(hideColor)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(hideFill, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(hideColor.opacity(0.6), lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption2)
            .tracking(3)
            .foregroundStyle(Palette.gold)
    }

    func field(
        _ prompt: String,
        text: Binding<String>,
        font: Font,
        focus field: Field
    ) -> some View {
        TextField(
            prompt,
            text: text,
            prompt: Text(prompt).foregroundStyle(Palette.dusk)
        )
        .font(font)
        .foregroundStyle(Palette.ink)
        .tint(Palette.gold)
        .submitLabel(.done)
        .focused($focus, equals: field)
        .onSubmit {
            focus = nil
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Palette.drawer, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(fieldStroke(for: field), lineWidth: 1)
        }
        .animation(.snappy(duration: 0.2), value: focus)
    }

    func glyphButton(_ glyph: Icon.Glyph) -> some View {
        let isSelected = model.glyph == glyph
        let color = isSelected ? Palette.champagne : Palette.mist

        return Button {
            model.glyph = glyph
        } label: {
            Image(systemName: glyph.symbolName)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    tileFill(isSelected: isSelected),
                    in: .rect(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            tileStroke(isSelected: isSelected),
                            lineWidth: 1
                        )
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func emojiButton(_ emoji: String) -> some View {
        let isSelected = model.emoji == emoji

        return Button {
            model.inputEmoji(emoji)
        } label: {
            Text(emoji)
                .font(.title3)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    tileFill(isSelected: isSelected),
                    in: .rect(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            tileStroke(isSelected: isSelected),
                            lineWidth: 1
                        )
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func colorButton(_ hex: String) -> some View {
        let isSelected = model.color == hex
        let ring = isSelected ? Palette.champagne : Color.clear

        return Button {
            model.color = hex
        } label: {
            Circle()
                .fill(Color(hex: hex) ?? Palette.mist)
                .padding(3)
                .overlay {
                    Circle()
                        .stroke(ring, lineWidth: 1.5)
                }
                .frame(width: 30, height: 30)
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension CategoryEditSheet {
    enum Field: Hashable {
        case name
        case text
    }

    enum TagEdit: Hashable {
        case add
        case rename(Int)
    }

    typealias MarkOption = CapsulePicker<CategoryEditModel.MarkKind>.Option

    static let markOptions: [MarkOption] = [
        .init("絵柄", value: .glyph),
        .init("絵文字", value: .emoji),
        .init("文字", value: .text)
    ]

    static let colorColumns = Array(
        repeating: GridItem(.flexible(), spacing: 2),
        count: 11
    )

    static let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: 6),
        count: 8
    )

    var tagItems: [TagLine<Int>.Item] {
        model.tags.enumerated().map { index, tag in
            TagLine.Item(id: index, name: tag.name)
        }
    }

    static var tagTransition: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }

    func deleteAction(for edit: TagEdit) -> (() -> Void)? {
        guard case let .rename(index) = edit else {
            return nil
        }

        return {
            model.removeTag(at: index)
            closeTag()
        }
    }

    var saveColor: Color {
        model.canSave ? Palette.gold : Palette.dusk
    }

    var hideColor: Color {
        model.isHidden ? Palette.gold : Palette.mist
    }

    var hideFill: Color {
        model.isHidden ? Palette.gold.opacity(0.1) : Color.clear
    }

    func fieldStroke(for field: Field) -> Color {
        focus == field ? Palette.gold : Palette.gold.opacity(0.35)
    }

    var customColor: Binding<Color> {
        Binding(
            get: {
                Color(hex: model.color) ?? Palette.mist
            },
            set: { color in
                model.color = color.hex
            }
        )
    }

    var textBinding: Binding<String> {
        Binding(
            get: {
                model.text
            },
            set: { value in
                model.inputText(value)
            }
        )
    }

    func tileFill(isSelected: Bool) -> Color {
        isSelected ? Palette.gold.opacity(0.14) : Color.clear
    }

    func tileStroke(isSelected: Bool) -> Color {
        isSelected ? Palette.gold : Palette.gold.opacity(0.14)
    }

    func addTag() {
        showTag(.add, name: "")
    }

    func editTag(at index: Int) {
        showTag(.rename(index), name: model.tags[index].name)
    }

    func showTag(
        _ edit: TagEdit,
        name: String
    ) {
        focus = nil
        tagName = name
        model.clearError()

        withAnimation(.snappy(duration: 0.25)) {
            tagEdit = edit
        }
    }

    func closeTag() {
        model.clearError()

        withAnimation(.snappy(duration: 0.2)) {
            tagEdit = nil
        }
    }

    func commitTag() {
        let isDone = switch tagEdit {
        case .add: model.addTag(tagName)
        case let .rename(index): model.renameTag(at: index, to: tagName)
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
