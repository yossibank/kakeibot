import Core
import Testing

struct BuddyTests {
    @Test
    func usesDefaultNameWhenEmpty() {
        #expect(Buddy.panda.name(" ") == "パンダ")
        #expect(Buddy.panda.name(" ミケ ") == "ミケ")
    }
}
