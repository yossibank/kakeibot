@testable import Features
import Testing

struct MemoTests {
    @Test
    func reusesValueForSameKey() {
        var memo = Memo<Int, String>()
        var made = 0

        _ = memo.value(for: 1) {
            made += 1
            return "a"
        }

        let value = memo.value(for: 1) {
            made += 1
            return "b"
        }

        #expect(value == "a")
        #expect(made == 1)
    }

    @Test
    func remakesValueWhenKeyChanges() {
        var memo = Memo<Int, String>()

        _ = memo.value(for: 1) {
            "a"
        }

        let value = memo.value(for: 2) {
            "b"
        }

        #expect(value == "b")
    }
}
