import Core

public extension RecordsModel {
    struct ListDay: Identifiable, Hashable {
        public let date: LocalDate
        public let day: EntryDay?

        public var id: LocalDate {
            date
        }
    }
}
