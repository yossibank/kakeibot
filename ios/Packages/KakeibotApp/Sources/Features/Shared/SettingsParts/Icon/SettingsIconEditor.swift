import Core
import DesignSystem
import SwiftUI

struct SettingsIconEditor<Field: Hashable>: View {
    @Bindable var model: SettingsIconEditorModel

    @Environment(\.themeStyle.displayFont) private var themeFont
    @Environment(\.themeStyle.textSize.scale) private var textScale
    @Environment(\.themeStyle.corner) private var corner

    var focus: FocusState<Field?>.Binding

    let textField: Field

    var body: some View {
        VStack(spacing: 16) {
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

private extension SettingsIconEditor {
    var colors: some View {
        LazyVGrid(columns: Self.colorColumns, spacing: 4) {
            ForEach(SettingsIconEditorModel.colors, id: \.self) { hex in
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
        VStack(alignment: .leading, spacing: 16) {
            ForEach(SettingsIconEditorModel.glyphSections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitle(section.title)

                    LazyVGrid(columns: Self.gridColumns, spacing: 8) {
                        ForEach(section.glyphs, id: \.self) { glyph in
                            glyphButton(glyph)
                        }
                    }
                }
            }
        }
    }

    var emojiChooser: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(SettingsIconEditorModel.emojiSections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitle(section.title)

                    LazyVGrid(columns: Self.gridColumns, spacing: 8) {
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
                font: .display(
                    .headline,
                    in: themeFont,
                    scale: textScale
                ),
                focus: focus,
                field: textField
            )

            SettingsCaption("「外」「推し」のように、短い文字をアイコンにできます")
        }
    }

    func glyphButton(_ glyph: Icon.Glyph) -> some View {
        let isSelected = model.glyph == glyph

        return Button {
            model.glyph = glyph
        } label: {
            tile(isSelected: isSelected) {
                Image(systemName: glyph.symbolName)
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.light)
                    .foregroundStyle(isSelected ? Palette.accent : Palette.subtext)
                    .frame(maxHeight: 20)
                    .padding(4)
            }
        }
        .buttonStyle(.plain)
    }

    func emojiButton(_ emoji: String) -> some View {
        let isSelected = model.emoji == emoji

        return Button {
            model.inputEmoji(emoji)
        } label: {
            tile(isSelected: isSelected) {
                Text(emoji)
                    .textFont(.title3)
            }
        }
        .buttonStyle(.plain)
    }

    func tile(
        isSelected: Bool,
        @ViewBuilder mark: () -> some View
    ) -> some View {
        let stroke = isSelected ? markColor : Palette.line

        return RoundedRectangle(cornerRadius: corner.radius(12), style: .continuous)
            .strokeBorder(stroke, lineWidth: 1)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                mark()
            }
            .contentShape(.rect)
    }

    func colorButton(_ hex: String) -> some View {
        let isSelected = model.color == hex
        let fill = Color(hex: hex) ?? Palette.subtext
        let ring = isSelected ? fill : Color.clear

        return Button {
            model.color = hex
        } label: {
            Circle()
                .fill(fill)
                .padding(4)
                .overlay {
                    Circle()
                        .strokeBorder(ring, lineWidth: 1.5)
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 30)
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension SettingsIconEditor {
    typealias MarkOption = CapsulePicker<SettingsIconEditorModel.MarkKind>.Option

    static var markOptions: [MarkOption] {
        [
            .init("絵柄", value: .glyph),
            .init("絵文字", value: .emoji),
            .init("文字", value: .text)
        ]
    }

    static var colorColumns: [GridItem] {
        let column = GridItem(.flexible(), spacing: 2)
        return Array(repeating: column, count: 11)
    }

    static var gridColumns: [GridItem] {
        let column = GridItem(.flexible(), spacing: 8)
        return Array(repeating: column, count: 8)
    }

    var customColor: Binding<Color> {
        Binding(
            get: {
                markColor
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

    var markColor: Color {
        Color(hex: model.color) ?? Palette.subtext
    }
}
