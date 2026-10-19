import Core
import DesignSystem
import SwiftUI

struct IconEditor<Field: Hashable>: View {
    @Bindable var model: IconEditModel

    var focus: FocusState<Field?>.Binding

    let textField: Field

    var body: some View {
        VStack(spacing: 16) {
            if !model.shelf.isEmpty {
                shelf
            }

            colors

            CapsulePicker(
                selection: $model.markKind,
                options: Self.markOptions
            )

            markChooser
        }
        .onChange(of: model.markKind) {
            focus.wrappedValue = nil
        }
        .onChange(of: model.glyph) {
            focus.wrappedValue = nil
        }
        .onChange(of: model.emoji) {
            focus.wrappedValue = nil
        }
        .onChange(of: model.color) {
            focus.wrappedValue = nil
        }
    }
}

private extension IconEditor {
    var shelf: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("棚から選ぶ")

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(model.shelf, id: \.id) { icon in
                        Button {
                            model.apply(icon)
                        } label: {
                            IconBadge(icon, size: 40)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    var colors: some View {
        LazyVGrid(columns: Self.colorColumns, spacing: 4) {
            ForEach(IconEditModel.colors, id: \.self) { hex in
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
            ForEach(IconEditModel.glyphSections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    SettingsSectionTitle(section.title)

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
            ForEach(IconEditModel.emojiSections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    SettingsSectionTitle(section.title)

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
            SettingsField(
                "3 文字まで",
                text: textBinding,
                font: .serif(.headline),
                focus: focus,
                field: textField
            )

            Text("「外」「推し」のように、短い文字をアイコンにできます")
                .font(.caption)
                .foregroundStyle(Palette.mist)
        }
    }

    func glyphButton(_ glyph: Icon.Glyph) -> some View {
        let isSelected = model.glyph == glyph
        let color = isSelected ? Palette.champagne : Palette.mist

        return Button {
            model.glyph = glyph
        } label: {
            Image(systemName: glyph.symbolName)
                .font(.sans(.headline, weight: .light))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    Self.tileFill(isSelected: isSelected),
                    in: .rect(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Self.tileStroke(isSelected: isSelected),
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
                    Self.tileFill(isSelected: isSelected),
                    in: .rect(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Self.tileStroke(isSelected: isSelected),
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

private extension IconEditor {
    typealias MarkOption = CapsulePicker<IconEditModel.MarkKind>.Option

    static var markOptions: [MarkOption] {
        [
            .init("絵柄", value: .glyph),
            .init("絵文字", value: .emoji),
            .init("文字", value: .text)
        ]
    }

    static var colorColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 2), count: 11)
    }

    static var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)
    }

    static func tileFill(isSelected: Bool) -> Color {
        isSelected ? Palette.gold.opacity(.subtle) : Color.clear
    }

    static func tileStroke(isSelected: Bool) -> Color {
        isSelected ? Palette.gold : Palette.gold.opacity(.subtle)
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
}
