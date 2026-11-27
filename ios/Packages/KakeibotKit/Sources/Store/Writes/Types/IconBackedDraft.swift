import Core
import Foundation
import GRDB

protocol IconBackedDraft: Sendable {
    associatedtype Record: IconBackedRecord

    func newIcon(at now: Date) throws -> Icon

    func newRecord(
        iconId: Icon.ID,
        sortOrder: Int,
        at now: Date
    ) throws -> Record

    func applied(
        to icon: Icon,
        at now: Date
    ) throws -> Icon

    func applied(
        to record: Record,
        at now: Date
    ) throws -> Record

    func sortOrder(in db: Database) throws -> Int
    func locked(by record: Record, in db: Database) throws -> Self
}

extension IconBackedDraft {
    func sortOrder(in db: Database) throws -> Int {
        try Record.nextSortOrder(in: db)
    }

    func locked(by record: Record, in db: Database) throws -> Self {
        self
    }
}
