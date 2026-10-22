import Core
import Testing

struct BuddyTests {
    @Test
    func usesDefaultNameWhenEmpty() {
        #expect(Buddy.cat.name(" ") == "たま")
        #expect(Buddy.cat.name(" ミケ ") == "ミケ")
    }
}
