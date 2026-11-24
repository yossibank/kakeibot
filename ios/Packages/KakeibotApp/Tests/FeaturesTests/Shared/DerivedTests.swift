@testable import FeatureModels
@testable import Features
import Observation
import Testing

@MainActor
struct DerivedTests {
    @Test
    func reusesValueUntilReadValueChanges() {
        let source = Source()
        let derived = Derived<Int>()
        var made = 0

        let make = {
            made += 1
            return source.count * 2
        }

        let first = derived.value(make)
        let second = derived.value(make)

        source.count = 3

        let third = derived.value(make)

        #expect(first == 2)
        #expect(second == 2)
        #expect(third == 6)
        #expect(made == 2)
    }

    @Test
    func keepsValueWhenUnreadValueChanges() {
        let source = Source()
        let derived = Derived<Int>()
        var made = 0

        let make = {
            made += 1
            return source.count
        }

        _ = derived.value(make)

        source.label = "b"

        _ = derived.value(make)

        #expect(made == 1)
    }

    @Test
    func tellsReaderWhenReadValueChanges() {
        let source = Source()
        let derived = Derived<Int>()
        var changes = 0

        _ = derived.value {
            source.count
        }

        withObservationTracking {
            _ = derived.value {
                source.count
            }
        } onChange: {
            MainActor.assumeIsolated {
                changes += 1
            }
        }

        source.label = "b"

        let before = changes

        source.count = 2

        #expect(before == 0)
        #expect(changes == 1)
    }

    @Test
    func tableDropsCellWhenReadValueChanges() {
        let source = Source()
        let table = DerivedTable<Int, Int>()

        let first = table.value(for: 1) { source.count }
        _ = table.value(for: 2) { source.count * 2 }

        source.count = 3

        let countAfterChange = table.count
        let second = table.value(for: 1) { source.count }

        #expect(first == 1)
        #expect(countAfterChange == 0)
        #expect(second == 3)
        #expect(table.count == 1)
    }
}

@MainActor
@Observable
private final class Source {
    var count = 1
    var label = "a"
}
