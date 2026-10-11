import Foundation

public struct CalendarStamp: Hashable, Sendable {
    public let id: ID
    public var date: LocalDate
    public var iconId: Icon.ID
    public var createdAt: Date

    public init(
        id: ID = ID(),
        date: LocalDate,
        iconId: Icon.ID,
        createdAt: Date
    ) {
        self.id = id
        self.date = date
        self.iconId = iconId
        self.createdAt = createdAt
    }
}

public extension CalendarStamp {
    typealias ID = Identifier<CalendarStamp>
}

extension CalendarStamp: Identifiable {}

extension CalendarStamp: Codable {}
