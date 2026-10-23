import Foundation

public struct EntryTemplateDraft: Hashable, Sendable {
    public var name: String
    public var type: Entry.Kind
    public var amount: Int?
    public var categoryId: EntryCategory.ID?
    public var tagId: EntryTag.ID?
    public var walletId: Wallet.ID?
    public var memo: String

    public init(
        name: String,
        type: Entry.Kind,
        amount: Int?,
        categoryId: EntryCategory.ID?,
        tagId: EntryTag.ID? = nil,
        walletId: Wallet.ID?,
        memo: String = ""
    ) {
        self.name = name
        self.type = type
        self.amount = amount
        self.categoryId = categoryId
        self.tagId = tagId
        self.walletId = walletId
        self.memo = memo
    }
}

public extension EntryTemplateDraft {
    enum Problem: String, CaseIterable, Codable, Error, Sendable {
        case emptyName
        case transfer
        case amountNotPositive
        case missingCategory
        case missingWallet
    }

    var problems: [Problem] {
        var problems: [Problem] = []

        if trimmedName.isEmpty {
            problems.append(.emptyName)
        }

        if type == .transfer {
            problems.append(.transfer)
        }

        if let amount, amount < 1 {
            problems.append(.amountNotPositive)
        }

        if categoryId == nil {
            problems.append(.missingCategory)
        }

        if walletId == nil {
            problems.append(.missingWallet)
        }

        return problems
    }

    init(_ template: EntryTemplate) {
        self.init(
            name: template.name,
            type: template.type,
            amount: template.amount,
            categoryId: template.categoryId,
            tagId: template.tagId,
            walletId: template.walletId,
            memo: template.memo ?? ""
        )
    }

    func newTemplate(
        sortOrder: Int,
        at now: Date
    ) throws -> EntryTemplate {
        let fields = try validated()

        return EntryTemplate(
            name: trimmedName,
            type: type,
            amount: amount,
            categoryId: fields.categoryId,
            tagId: tagId,
            walletId: fields.walletId,
            memo: trimmedMemo,
            sortOrder: sortOrder,
            createdAt: now,
            updatedAt: now
        )
    }

    func applied(
        to template: EntryTemplate,
        at now: Date
    ) throws -> EntryTemplate {
        let fields = try validated()

        var updated = template

        updated.name = trimmedName
        updated.type = type
        updated.amount = amount
        updated.categoryId = fields.categoryId
        updated.tagId = tagId
        updated.walletId = fields.walletId
        updated.memo = trimmedMemo
        updated.updatedAt = now

        return updated
    }
}

private extension EntryTemplateDraft {
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedMemo: String? {
        let trimmed = memo.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmed.isEmpty ? nil : trimmed
    }

    func validated() throws -> (
        categoryId: EntryCategory.ID,
        walletId: Wallet.ID
    ) {
        if let problem = problems.first {
            throw problem
        }

        guard let categoryId, let walletId else {
            throw Problem.missingCategory
        }

        return (categoryId, walletId)
    }
}
