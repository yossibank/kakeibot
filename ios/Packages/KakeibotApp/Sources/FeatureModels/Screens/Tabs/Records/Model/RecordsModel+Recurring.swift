import Core

public extension RecordsModel {
    struct ListDay: Identifiable, Hashable {
        public let date: LocalDate
        public let day: EntryDay?
    }
}

public extension RecordsModel.ListDay {
    var id: LocalDate {
        date
    }
}
