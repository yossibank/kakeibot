import Core
import GRDB

public extension AppDatabase {
    func setMonthStartDay(_ startDay: MonthStartDay) async throws {
        try await writer.write { db in
            let setting = Setting(
                key: .monthStartDay,
                value: String(startDay.day)
            )

            try setting.save(db)
        }
    }
}
