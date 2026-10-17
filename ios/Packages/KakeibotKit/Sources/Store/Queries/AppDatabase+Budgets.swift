import Core
import GRDB

public extension AppDatabase {
    func budgetUpdates() -> some AsyncSequence<[Budget], any Error> {
        ValueObservation
            .tracking(Self.budgets)
            .values(in: writer)
    }

    func budgets() async throws -> [Budget] {
        try await writer.read(Self.budgets)
    }
}

extension AppDatabase {
    static func budgets(in db: Database) throws -> [Budget] {
        try Budget.order(Column("from_month")).fetchAll(db)
    }
}
