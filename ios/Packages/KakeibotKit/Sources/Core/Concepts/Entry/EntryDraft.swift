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
    public var billMonth: YearMonth?
    public var fee: Int
    public var items: [EntryItem.Draft]?
    public var taxIncluded: Bool

    public init(
        type: Entry.Kind,
        amount: Int,
        date: LocalDate,
        categoryId: EntryCategory.ID?,
        tagId: EntryTag.ID? = nil,
        templateId: EntryTemplate.ID? = nil,
        walletId: Wallet.ID,
        toWalletId: Wallet.ID? = nil,
        memo: String = "",
        billMonth: YearMonth? = nil,
        fee: Int = 0,
        items: [EntryItem.Draft]? = nil,
        taxIncluded: Bool = false
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
        self.billMonth = billMonth
        self.fee = fee
        self.items = items
        self.taxIncluded = taxIncluded
    }

    public init(_ entry: Entry) {
        self.init(
            type: entry.type,
            amount: entry.amount,
            date: entry.date,
            categoryId: entry.categoryId,
            tagId: entry.tagId,
            templateId: entry.templateId,
            walletId: entry.walletId,
            toWalletId: entry.toWalletId,
            memo: entry.memo ?? "",
            billMonth: entry.billMonth,
            taxIncluded: entry.taxIncluded
        )
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
        case feeNegative
        case feeOnNonTransfer
        case itemsOnTransfer
        case itemNameEmpty
        case itemQuantityNotPositive
    }

    var problems: [Problem] {
        let amountProblems: [Problem] = amount < 1 ? [.amountNotPositive] : []
        let tagProblems: [Problem] = tagId != nil && categoryId == nil
            ? [.tagWithoutCategory]
            : []
        return amountProblems + typeProblems + tagProblems + feeProblems + itemProblems
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
            billMonth: billMonth,
            taxIncluded: includesTax,
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
        updated.billMonth = billMonth
        updated.updatedAt = now

        if items != nil {
            updated.taxIncluded = includesTax
        }

        return updated
    }
}

private extension EntryDraft {
    var includesTax: Bool {
        taxIncluded && !(items ?? []).isEmpty
    }

    var typeProblems: [Problem] {
        switch type {
        case .expense, .income:
            return categoryId == nil ? [.missingCategory] : []

        case .transfer:
            let categoryProblems: [Problem] = categoryId == nil ? [] : [.categoryOnTransfer]
            return categoryProblems + destinationProblems
        }
    }

    var feeProblems: [Problem] {
        switch (fee, type) {
        case (..<0, _): [.feeNegative]
        case (1..., .expense), (1..., .income): [.feeOnNonTransfer]
        default: []
        }
    }

    var itemProblems: [Problem] {
        let items = items ?? []
        let transferProblems: [Problem] = type == .transfer && !items.isEmpty
            ? [.itemsOnTransfer]
            : []
        let nameProblems: [Problem] = items.contains { $0.trimmedName.isEmpty }
            ? [.itemNameEmpty]
            : []
        let quantityProblems: [Problem] = items.contains { $0.quantity < 1 }
            ? [.itemQuantityNotPositive]
            : []
        return transferProblems + nameProblems + quantityProblems
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
