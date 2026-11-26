@testable import FeatureModels
import Testing

struct ShownTests {
    @Test
    func showsOnePromptAtATime() {
        var shown = Shown<Prompt>()

        shown[.menu] = true
        let menu = shown[.menu]

        shown[.delete] = true

        #expect(menu)
        #expect(!shown[.menu])
        #expect(shown[.delete])
        #expect(!shown.isShowing(.discard))
        #expect(shown.current == .delete)
    }

    @Test
    func closesOnlyThePromptInFront() {
        var shown = Shown<Prompt>()

        shown.show(.hide)
        shown[.discard] = false
        let kept = shown.isShowing(.hide)

        shown.close(.hide)

        #expect(kept)
        #expect(shown == Shown())
    }

    @Test
    func closesWhateverIsShown() {
        var shown = Shown(Prompt.menu)

        shown.closeAll()

        #expect(shown.current == nil)
    }

    @Test
    func setsAndClearsItem() {
        var shown = Shown<Prompt>()

        shown.item = .menu
        let opened = shown.current

        shown.item = nil
        let cleared = shown.current

        shown.show(.delete)
        shown.closeAll()

        #expect(opened == .menu)
        #expect(cleared == nil)
        #expect(shown.current == nil)
    }
}

extension ShownTests {
    enum Prompt: Hashable, Sendable {
        case menu
        case discard
        case hide
        case delete
    }
}
