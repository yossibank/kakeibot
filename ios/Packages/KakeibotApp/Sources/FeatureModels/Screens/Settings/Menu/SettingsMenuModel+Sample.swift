#if DEBUG
import Core

public extension SettingsMenuModel {
    func insertSample(today: LocalDate) async throws {
        try await SettingsMenuSampleData.insert(
            into: dependencies.database,
            today: today,
            now: dependencies.clock.now
        )
    }
}
#endif
