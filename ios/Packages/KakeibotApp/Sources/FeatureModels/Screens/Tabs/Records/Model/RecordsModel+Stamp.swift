import Core
import Foundation
import Store

public extension RecordsModel {
    func stamp(
        _ icon: Icon,
        on date: LocalDate
    ) async {
        do {
            try await dependencies.database.stamp(icon.id, on: date, at: dependencies.clock.now)
        } catch {
            state.notices.error.show(Self.saveFailedMessage, for: error)
        }
    }

    func removeStamp(on date: LocalDate) async {
        do {
            try await dependencies.database.removeStamp(on: date)
        } catch {
            state.notices.error.show(Self.saveFailedMessage, for: error)
        }
    }

    func stampEditModel() -> StampEditModel {
        StampEditModel(parts: dependencies)
    }

    func toggleNoSpendDay(on date: LocalDate) async {
        do {
            if input.noSpendDays.contains(date) {
                try await dependencies.database.unmarkNoSpendDay(date)
            } else {
                try await dependencies.database.markNoSpendDay(date, at: dependencies.clock.now)
            }
        } catch {
            state.notices.error.show(Self.saveFailedMessage, for: error)
        }
    }
}
