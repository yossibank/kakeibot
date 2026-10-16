import Foundation

public struct EntryDraft: Hashable, Sendable {
    public var type: Entry.Kind
    public var amount: Int
    public var date: LocalDate
    public var categoryId: EntryCategory.ID?
    public var tagId: EntryTag.ID?
    public var templateId: EntryTemplate.ID?
    public var walletId: Wallet.ID
    public var toWalletId: Wallet.ID?
    public var memo: String

    public init(
        type: Entry.Kind,
        amount: Int,
        date: LocalDate,
        categoryId: EntryCategory.ID?,
        tagId: EntryTag.ID? = nil,
        templateId: EntryTemplate.ID? = nil,
        walletId: Wallet.ID,
        toWalletId: Wallet.ID? = nil,
        memo: String = ""
    ) {
        self.type = type
        self.amount = amount
        self.date = date
        self.categoryId = categoryId
        self.tagId = tagId
        self.templateId = templateId
        self.walletId = walletId
        self.toWalletId = toWalletId
        self.memo = memo
    }
}

public extension EntryDraft {
    enum Problem: String, CaseIterable, Codable, Error, Sendable {
        case amountNotPositive
        case missingCategory
        case categoryOnTransfer
        case missingDestination
        case sameWallet
        case tagWithoutCategory
    }

    var problems: [Problem] {
        let amountProblems: [Problem] = amount < 1 ? [.amountNotPositive] : []

        let tagProblems: [Problem] = tagId != nil && categoryId == nil
            ? [.tagWithoutCategory]
            : []

        return amountProblems + typeProblems + tagProblems
    }

    init(_ entry: Entry) {
        self.init(
            type: entry.type,
            amount: entry.amount,
            date: entry.date,
            categoryId: entry.categoryId,
            tagId: entry.tagId,
            templateId: entry.templateId,
            walletId: entry.walletId,
            toWalletId: entry.toWalletId,
            memo: entry.memo ?? ""
        )
    }

    func newEntry(at now: Date) throws -> Entry {
        try validate()

        return Entry(
            type: type,
            amount: amount,
            date: date,
            categoryId: categoryId,
            tagId: tagId,
            templateId: templateId,
            walletId: walletId,
            toWalletId: destination,
            memo: trimmedMemo,
            createdAt: now,
            updatedAt: now
        )
    }

    func applied(
        to entry: Entry,
        at now: Date
    ) throws -> Entry {
        try validate()

        var updated = entry
        updated.type = type
        updated.amount = amount
        updated.date = date
        updated.categoryId = categoryId
        updated.tagId = tagId
        updated.templateId = templateId
        updated.walletId = walletId
        updated.toWalletId = destination
        updated.memo = trimmedMemo
        updated.updatedAt = now
        return updated
    }
}

private extension EntryDraft {
    var typeProblems: [Problem] {
        switch type {
        case .expense, .income:
            return categoryId == nil ? [.missingCategory] : []
        case .transfer:
            let categoryProblems: [Problem] = categoryId == nil
                ? []
                : [.categoryOnTransfer]
            return categoryProblems + destinationProblems
        }
    }

    var destinationProblems: [Problem] {
        guard let toWalletId else {
            return [.missingDestination]
        }

        return toWalletId == walletId ? [.sameWallet] : []
    }

    var destination: Wallet.ID? {
        type == .transfer ? toWalletId : nil
    }

    var trimmedMemo: String? {
        let trimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func validate() throws {
        if let problem = problems.first {
            throw problem
        }
    }
}
