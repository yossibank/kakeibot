import Core

public struct WidgetRecord: Hashable, Sendable {
    public let entryId: Entry.ID
    public let clearedNoSpendDate: LocalDate?

    public init(
        entryId: Entry.ID,
        clearedNoSpendDate: LocalDate? = nil
    ) {
        self.entryId = entryId
        self.clearedNoSpendDate = clearedNoSpendDate
    }

    public init?(_ text: String) {
        let parts = text.split(separator: ",", maxSplits: 1).map(String.init)

        guard let entryId = parts.first.flatMap(Entry.ID.init) else {
            return nil
        }

        let clearedNoSpendDate = parts.dropFirst().first.flatMap(LocalDate.init)

        self.init(entryId: entryId, clearedNoSpendDate: clearedNoSpendDate)
    }
}

public extension WidgetRecord {
    var text: String {
        guard let clearedNoSpendDate else {
            return entryId.description
        }

        return "\(entryId),\(clearedNoSpendDate)"
    }
}
