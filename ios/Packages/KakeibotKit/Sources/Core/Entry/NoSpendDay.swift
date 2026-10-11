import Foundation

public struct NoSpendDay: Hashable, Sendable {
    public let date: LocalDate
    public var createdAt: Date

    public init(
        date: LocalDate,
        createdAt: Date
    ) {
        self.date = date
        self.createdAt = createdAt
    }
}

extension NoSpendDay: Identifiable {
    public var id: LocalDate {
        date
    }
}

extension NoSpendDay: Codable {}
