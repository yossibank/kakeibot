@testable import FeatureModels
import Testing

@MainActor
struct ModelTaskTests {
    @Test
    func returnsValueAndMarksRunning() async {
        let task = ModelTask()
        var whileRunning = false

        let value = await task.attempt {
            whileRunning = task.isRunning
            return 3
        }

        #expect(value == 3)
        #expect(whileRunning)
        #expect(!task.isRunning)
    }

    @Test
    func runsActionWhileRunning() async {
        let task = ModelTask()
        var inner = 0
        var count = 0

        await task.attempt {
            count += 1
            inner = await task.attempt {
                count += 1
                return 1
            }
        }

        #expect(count == 2)
        #expect(inner == 1)
        #expect(!task.isRunning)
    }

    @Test
    func stopsRunningAfterFailure() async {
        let task = ModelTask()

        await #expect(throws: Failure.self) {
            try await task.attempt {
                throw Failure()
            }
        }

        let value = await task.attempt {
            1
        }

        #expect(!task.isRunning)
        #expect(value == 1)
    }

    @Test
    func marksOnlyTheRunningKey() async {
        let task = ModelTask<Work>()
        var first = false
        var second = true
        var any = false

        await task.attempt(.first) {
            first = task.isRunning(.first)
            second = task.isRunning(.second)
            any = task.isRunning
        }

        #expect(first)
        #expect(!second)
        #expect(any)
        #expect(!task.isRunning(.first))
        #expect(!task.isRunning)
    }

    @Test
    func keepsKeyRunningUntilOuterAttemptEnds() async {
        let task = ModelTask<Work>()
        var afterInner = false
        var otherWhileRunning = true

        await task.attempt(.first) {
            await task.attempt(.first) {}
            afterInner = task.isRunning(.first)
            otherWhileRunning = task.isRunning(where: { $0 != .first })
        }

        #expect(afterInner)
        #expect(!otherWhileRunning)
        #expect(!task.isRunning(.first))
    }

    @Test
    func stopsRunningKeyAfterFailure() async {
        let task = ModelTask<Work>()

        await #expect(throws: Failure.self) {
            try await task.attempt(.first) {
                throw Failure()
            }
        }

        #expect(!task.isRunning(.first))
        #expect(!task.isRunning)
    }
}

extension ModelTaskTests {
    struct Failure: Error {}

    enum Work: Hashable, Sendable {
        case first
        case second
    }
}
