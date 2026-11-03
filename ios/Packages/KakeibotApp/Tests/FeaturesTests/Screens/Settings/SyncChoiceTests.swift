import Features
import Foundation
import Store
import Testing

struct SyncChoiceTests {
    @Test(arguments: [
        (local: 0.0, cloud: 120.0, newer: SyncChoice.Side?.some(.cloud)),
        (local: 120.0, cloud: 0.0, newer: .local),
        (local: 0.0, cloud: 30.0, newer: nil)
    ])
    func comparesByTheMinute(
        local: TimeInterval,
        cloud: TimeInterval,
        newer: SyncChoice.Side?
    ) {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let choice = SyncChoice(
            local: SyncSummary(entryCount: 1, updatedAt: start + local),
            cloud: SyncSummary(entryCount: 1, updatedAt: start + cloud)
        )

        #expect(choice.newer == newer)
    }

    @Test
    func treatsTheOnlyDatedSideAsNewer() {
        let dated = SyncSummary(entryCount: 1, updatedAt: Date(timeIntervalSinceReferenceDate: 0))
        let undated = SyncSummary(entryCount: 0, updatedAt: nil)

        #expect(SyncChoice(local: dated, cloud: undated).newer == .local)
        #expect(SyncChoice(local: undated, cloud: dated).newer == .cloud)
        #expect(SyncChoice(local: undated, cloud: undated).newer == nil)
    }
}
