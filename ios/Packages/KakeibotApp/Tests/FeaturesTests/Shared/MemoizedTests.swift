@testable import Features
import Testing

struct MemoizedTests {
    @Test
    func reusesValueForSameKey() {
        var memo = Memoized<Int, String>()
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
        var memo = Memoized<Int, String>()

        _ = memo.value(for: 1) {
            "a"
        }

        let value = memo.value(for: 2) {
            "b"
        }

        #expect(value == "b")
    }
}
