@testable import AppFeature
import Store
import Testing

@MainActor
struct AppModelTests {
    @Test
    func opensDatabase() {
        let model = AppModel(openDatabase: AppDatabase.inMemory)

        model.open()

        guard case .ready = model.launch else {
            Issue.record("Expected ready, got \(model.launch)")
            return
        }
    }

    @Test
    func reportsFailureToOpen() {
        let model = AppModel {
            throw AppDatabase.SetupError.appGroupUnavailable
        }

        model.open()

        guard case .failed = model.launch else {
            Issue.record("Expected failed, got \(model.launch)")
            return
        }
    }
}
