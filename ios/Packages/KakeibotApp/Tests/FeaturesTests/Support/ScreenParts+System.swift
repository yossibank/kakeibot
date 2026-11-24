import FeatureModels
import Store

extension ScreenParts {
    static func system(_ database: AppDatabase) -> ScreenParts {
        ScreenParts(database: database, clock: .system)
    }
}
