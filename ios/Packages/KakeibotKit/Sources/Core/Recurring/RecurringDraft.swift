import Foundation

public struct RecurringDraft: Hashable, Sendable {
    public var type: Entry.Kind
    public var amount: Int
    public var categoryId: EntryCategory.ID?
    public var walletId: Wallet.ID?
    public var toWalletId: Wallet.ID?
    public var memo: String
    public var frequency: Recurring.Frequency
    public var month: Int
    public var day: Int
    public var holidayShift: Recurring.HolidayShift
    public var startDate: LocalDate
    public var endDate: LocalDate?
    public var remindDaysBefore: Int?

    public init(
        type: Entry.Kind,
        amount: Int,
        categoryId: EntryCategory.ID?,
        walletId: Wallet.ID?,
        toWalletId: Wallet.ID? = nil,
        memo: String = "",
        frequency: Recurring.Frequency,
        month: Int,
        day: Int,
        holidayShift: Recurring.HolidayShift = .none,
        startDate: LocalDate,
        endDate: LocalDate? = nil,
        remindDaysBefore: Int? = nil
    ) {
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
        self.startDate = startDate
        self.endDate = endDate
        self.remindDaysBefore = remindDaysBefore
    }
}

public extension RecurringDraft {
    enum Problem: String, CaseIterable, Codable, Error, Sendable {
        case amountNotPositive
        case missingCategory
        case categoryOnTransfer
        case missingWallet
        case missingDestination
        case sameWallet
        case dayOutOfRange
        case monthOutOfRange
        case endBeforeStart
        case remindOutOfRange
    }

    static let remindRange = 0...30

    var problems: [Problem] {
        var problems: [Problem] = []

        if amount < 1 {
            problems.append(.amountNotPositive)
        }

        problems += categoryProblems

        if walletId == nil {
            problems.append(.missingWallet)
        }

        problems += destinationProblems

        if !(1...31).contains(day) {
            problems.append(.dayOutOfRange)
        }

        if frequency == .yearly, !(1...12).contains(month) {
            problems.append(.monthOutOfRange)
        }

        if let endDate, endDate < startDate {
            problems.append(.endBeforeStart)
        }

        if let days = remindDaysBefore, !Self.remindRange.contains(days) {
            problems.append(.remindOutOfRange)
        }

        return problems
    }

    init(_ recurring: Recurring) {
        self.init(
            type: recurring.type,
            amount: recurring.amount,
            categoryId: recurring.categoryId,
            walletId: recurring.walletId,
            toWalletId: recurring.toWalletId,
            memo: recurring.memo ?? "",
            frequency: recurring.frequency,
            month: recurring.month ?? recurring.startDate.month,
            day: recurring.day,
            holidayShift: recurring.holidayShift,
            startDate: recurring.startDate,
            endDate: recurring.endDate,
            remindDaysBefore: recurring.remindDaysBefore
        )
    }

    func newRecurring(at now: Date) throws -> Recurring {
        let fields = try validated()

        return Recurring(
            type: type,
            amount: amount,
            categoryId: fields.categoryId,
            walletId: fields.walletId,
            toWalletId: destination,
            memo: trimmedMemo,
            frequency: frequency,
            month: yearlyMonth,
            day: day,
            holidayShift: holidayShift,
            startDate: startDate,
            endDate: endDate,
            remindDaysBefore: remindDaysBefore,
            createdAt: now,
            updatedAt: now
        )
    }

    func applied(
        to recurring: Recurring,
        at now: Date
    ) throws -> Recurring {
        let fields = try validated()

        var updated = recurring
        updated.type = type
        updated.amount = amount
        updated.categoryId = fields.categoryId
        updated.walletId = fields.walletId
        updated.toWalletId = destination
        updated.memo = trimmedMemo
        updated.frequency = frequency
        updated.month = yearlyMonth
        updated.day = day
        updated.holidayShift = holidayShift
        updated.startDate = startDate
        updated.endDate = endDate
        updated.remindDaysBefore = remindDaysBefore
        updated.updatedAt = now
        return updated
    }
}

private extension RecurringDraft {
    var categoryProblems: [Problem] {
        switch type {
        case .expense, .income:
            categoryId == nil ? [.missingCategory] : []
        case .transfer:
            categoryId == nil ? [] : [.categoryOnTransfer]
        }
    }

    var destinationProblems: [Problem] {
        guard type == .transfer else {
            return []
        }

        guard let toWalletId else {
            return [.missingDestination]
        }

        return toWalletId == walletId ? [.sameWallet] : []
    }

    var destination: Wallet.ID? {
        type == .transfer ? toWalletId : nil
    }

    var yearlyMonth: Int? {
        frequency == .yearly ? month : nil
    }

    var trimmedMemo: String? {
        let trimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func validated() throws -> (
        categoryId: EntryCategory.ID?,
        walletId: Wallet.ID
    ) {
        if let problem = problems.first {
            throw problem
        }

        guard let walletId else {
            throw Problem.missingWallet
        }

        return (categoryId, walletId)
    }
}
