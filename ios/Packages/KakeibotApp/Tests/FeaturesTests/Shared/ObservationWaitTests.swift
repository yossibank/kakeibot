import Testing
import TestSupport

@MainActor
struct ObservationWaitTests {
    @Test
    func recordsTimeoutWhenReadyWithoutNotice() async {
        let flag = Flag()
        let change = Task {
            try await Task.sleep(for: .milliseconds(10))
            flag.isOn = true
        }

        await withKnownIssue {
            await ObservationWait.until(timeout: .milliseconds(300)) {
                flag.isOn
            }
        }

        change.cancel()
    }
}

extension ObservationWaitTests {
    @MainActor
    final class Flag {
        var isOn = false
    }
}
