import Core
import Features
import Testing

@MainActor
struct SettingsIconEditorModelTests {
    @Test(arguments: ["1", "©", "\u{263A}", "a", "あ"])
    func refusesCharactersThatAreNotEmoji(_ value: String) {
        let model = SettingsIconEditorModel(glyph: .food)

        model.inputEmoji(value)

        #expect(model.emoji.isEmpty)
    }

    @Test(arguments: ["🍙", "🇯🇵", "👍🏽", "👨‍👩‍👧", "1️⃣", "\u{263A}\u{FE0F}"])
    func acceptsEmoji(_ value: String) {
        let model = SettingsIconEditorModel(glyph: .food)

        model.inputEmoji(value)

        #expect(model.emoji == value)
    }

    @Test
    func keepsLastEmojiOfInput() {
        let model = SettingsIconEditorModel(glyph: .food)

        model.inputEmoji("🍙a🍣1")

        #expect(model.emoji == "🍣")
    }

    @Test
    func cutsTextAtLimit() {
        let model = SettingsIconEditorModel(glyph: .food)
        let long = String(repeating: "あ", count: IconDraft.maxTextLength + 3)

        model.inputText(long)

        #expect(model.text.count == IconDraft.maxTextLength)
    }

    @Test
    func appliesSavedMark() {
        let model = SettingsIconEditorModel(glyph: .food)
        let emoji = IconDraft(mark: .emoji("🍣"), color: "#4A6FA5")
        let text = IconDraft(mark: .text("家"), color: "#E07A5F")

        model.apply(emoji)
        let appliedEmoji = model.draft
        model.apply(text)

        #expect(appliedEmoji == emoji)
        #expect(model.markKind == .text)
        #expect(model.draft == text)
        #expect(model.preview.text == "家")
        #expect(model.preview.emoji == nil)
    }
}
