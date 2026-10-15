@testable import AppFeature
import Store
import Testing

@MainActor
struct AppModelTests {
    @Test
    func opensDatabase() async {
        let model = AppModel(openDatabase: AppDatabase.inMemory)

        await model.open()

        guard case .ready = model.launch else {
            Issue.record("Expected ready, got \(model.launch)")
            return
        }
    }

    @Test
    func reportsFailureToOpen() async {
        let model = AppModel {
            throw AppDatabase.SetupError.appGroupUnavailable
        }

        await model.open()

        guard case .failed = model.launch else {
            Issue.record("Expected failed, got \(model.launch)")
            return
        }
    }
}
