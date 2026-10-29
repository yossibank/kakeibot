import Foundation

public struct Recurring: Hashable, Identifiable, Sendable {
    public let id: ID

    public var type: Entry.Kind
    public var amount: Int
    public var categoryId: EntryCategory.ID?
    public var walletId: Wallet.ID
    public var toWalletId: Wallet.ID?
    public var memo: String?
    public var frequency: Frequency
    public var month: Int?
    public var day: Int
    public var holidayShift: HolidayShift
    public var closingDay: Int?
    public var fee: Int?
    public var startDate: LocalDate
    public var endDate: LocalDate?
    public var remindDaysBefore: Int?
    public var generatedUntil: LocalDate?
    public var sortOrder: Int
    public var archivedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        type: Entry.Kind,
        amount: Int,
        categoryId: EntryCategory.ID?,
        walletId: Wallet.ID,
        toWalletId: Wallet.ID? = nil,
        memo: String? = nil,
        frequency: Frequency,
        month: Int? = nil,
        day: Int,
        holidayShift: HolidayShift = .none,
        closingDay: Int? = nil,
        fee: Int? = nil,
        startDate: LocalDate,
        endDate: LocalDate? = nil,
        remindDaysBefore: Int? = nil,
        generatedUntil: LocalDate? = nil,
        sortOrder: Int = 0,
        archivedAt: Date? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.categoryId = categoryId
        self.walletId = walletId
        self.toWalletId = toWalletId
        self.memo = memo
        self.frequency = frequency
        self.month = month
        self.day = day
        self.holidayShift = holidayShift
        self.closingDay = closingDay
        self.fee = fee
        self.startDate = startDate
        self.endDate = endDate
        self.remindDaysBefore = remindDaysBefore
        self.generatedUntil = generatedUntil
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public extension Recurring {
    typealias ID = Identifier<Recurring>

    enum Frequency: String, CaseIterable, Codable, Sendable {
        case monthly
        case yearly
    }

    enum HolidayShift: String, CaseIterable, Codable, Sendable {
        case none
        case previous
        case next
    }
}

extension Recurring: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case amount
        case categoryId
        case walletId
        case toWalletId
        case memo
        case frequency
        case month
        case day
        case holidayShift
        case closingDay
        case fee
        case startDate
        case endDate
        case remindDaysBefore
        case generatedUntil
        case sortOrder
        case archivedAt
        case createdAt
        case updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let shift = try container.decodeIfPresent(HolidayShift.self, forKey: .holidayShift)
        let id = try container.decode(ID.self, forKey: .id)
        let type = try container.decode(Entry.Kind.self, forKey: .type)
        let amount = try container.decode(Int.self, forKey: .amount)
        let categoryId = try container.decodeIfPresent(EntryCategory.ID.self, forKey: .categoryId)
        let walletId = try container.decode(Wallet.ID.self, forKey: .walletId)
        let toWalletId = try container.decodeIfPresent(Wallet.ID.self, forKey: .toWalletId)
        let memo = try container.decodeIfPresent(String.self, forKey: .memo)
        let frequency = try container.decode(Frequency.self, forKey: .frequency)
        let month = try container.decodeIfPresent(Int.self, forKey: .month)
        let day = try container.decode(Int.self, forKey: .day)
        let closingDay = try container.decodeIfPresent(Int.self, forKey: .closingDay)
        let fee = try container.decodeIfPresent(Int.self, forKey: .fee)
        let startDate = try container.decode(LocalDate.self, forKey: .startDate)
        let endDate = try container.decodeIfPresent(LocalDate.self, forKey: .endDate)
        let remindDaysBefore = try container.decodeIfPresent(Int.self, forKey: .remindDaysBefore)
        let generatedUntil = try container.decodeIfPresent(LocalDate.self, forKey: .generatedUntil)
        let sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        let archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        self.init(
            id: id,
            type: type,
            amount: amount,
            categoryId: categoryId,
            walletId: walletId,
            toWalletId: toWalletId,
            memo: memo,
            frequency: frequency,
            month: month,
            day: day,
            holidayShift: shift ?? .none,
            closingDay: closingDay,
            fee: fee,
            startDate: startDate,
            endDate: endDate,
            remindDaysBefore: remindDaysBefore,
            generatedUntil: generatedUntil,
            sortOrder: sortOrder,
            archivedAt: archivedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(amount, forKey: .amount)
        try container.encodeOrNull(categoryId, forKey: .categoryId)
        try container.encode(walletId, forKey: .walletId)
        try container.encodeOrNull(toWalletId, forKey: .toWalletId)
        try container.encodeOrNull(memo, forKey: .memo)
        try container.encode(frequency, forKey: .frequency)
        try container.encodeOrNull(month, forKey: .month)
        try container.encode(day, forKey: .day)
        try container.encode(holidayShift, forKey: .holidayShift)
        try container.encodeOrNull(closingDay, forKey: .closingDay)
        try container.encodeOrNull(fee, forKey: .fee)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeOrNull(endDate, forKey: .endDate)
        try container.encodeOrNull(remindDaysBefore, forKey: .remindDaysBefore)
        try container.encodeOrNull(generatedUntil, forKey: .generatedUntil)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encodeOrNull(archivedAt, forKey: .archivedAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
