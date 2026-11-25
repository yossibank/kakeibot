import FeatureModels
import Store
import Testing

@MainActor
struct ScreenPerformingTests {
    @Test
    func runsModelWorkUntilItEnds() async throws {
        let database = try AppDatabase.inMemory()
        let model = WalletListModel(parts: .system(database))

        await model.perform {
            await $0.loadFold(\.hint)
        }.value

        #expect(model.input.hint.isClosed == false)
    }

    @Test
    func startsWorkAfterCallerReturns() async {
        let steps = Steps()

        let work = steps.perform {
            $0.values.append(1)
        }
        let valuesAtReturn = steps.values

        await work.value

        #expect(valuesAtReturn.isEmpty)
        #expect(steps.values == [1])
    }

    @Test
    func startsWorksInCalledOrder() async {
        let steps = Steps()

        let first = steps.perform {
            $0.values.append(1)
        }
        let second = steps.perform {
            $0.values.append(2)
        }

        await first.value
        await second.value

        #expect(steps.values == [1, 2])
    }
}

@MainActor
private final class Steps: ScreenPerforming {
    var values: [Int] = []
}
