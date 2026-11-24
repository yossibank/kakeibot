import Store

public extension ScreenParts {
    static func preview() -> ScreenParts? {
        guard let database = try? AppDatabase.inMemory() else {
            return nil
        }

        let clock = ScreenClock.system

        try? database.insertDefaultsIfEmpty(at: clock.now)
        try? database.insertShelfIfEmpty(at: clock.now)

        return ScreenParts(database: database, clock: clock)
    }
}
