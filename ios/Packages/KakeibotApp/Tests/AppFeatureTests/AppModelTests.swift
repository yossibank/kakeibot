@testable import AppFeature
import Store
import Testing

@MainActor
struct AppModelTests {
    @Test
    func asksFirstSetupThenOpens() async {
        let model = AppModel(openDatabase: AppDatabase.inMemory)

        await model.open()

        guard case .onboarding = model.launch else {
            Issue.record("Expected onboarding, got \(model.launch)")
            return
        }

        model.finishOnboarding()

        guard case .ready = model.launch else {
            Issue.record("Expected ready, got \(model.launch)")
            return
        }
    }

    @Test
    func opensDatabaseAfterFirstSetup() async throws {
        let database = try AppDatabase.inMemory()
        try await database.completeOnboarding()
        let model = AppModel { database }

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
