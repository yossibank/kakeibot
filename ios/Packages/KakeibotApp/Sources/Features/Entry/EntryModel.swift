import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class EntryModel {
    public var date: LocalDate
    public var categoryId: EntryCategory.ID?
    public var walletId: Wallet.ID?
    public var memo = ""

    public private(set) var type: Entry.Kind = .expense
    public private(set) var amount = 0
    public private(set) var options: EntryOptions?
    public private(set) var errorMessage: String?

    private let database: AppDatabase
    private let editingId: Entry.ID?

    public init(
        database: AppDatabase,
        editing id: Entry.ID? = nil,
        date: LocalDate
    ) {
        self.database = database
        self.editingId = id
        self.date = date
    }
}

public extension EntryModel {
    struct WalletSection {
        public let kind: Wallet.Kind
        public let wallets: [Wallet]
    }

    static let categoriesPerPage = 12

    var isEditing: Bool {
        editingId != nil
    }

    var categories: [EntryCategory] {
        categories(for: type)
    }

    var categoryPages: [[EntryCategory]] {
        stride(from: 0, to: categories.count, by: Self.categoriesPerPage).map { start in
            let end = min(start + Self.categoriesPerPage, categories.count)
            return Array(categories[start..<end])
        }
    }

    var selectedCategory: EntryCategory? {
        categories.first { $0.id == categoryId }
    }

    var wallets: [Wallet] {
        options?.wallets ?? []
    }

    var walletSections: [WalletSection] {
        Wallet.Kind.allCases.compactMap { kind in
            let wallets = wallets.filter { $0.kind == kind }
            return wallets.isEmpty ? nil : WalletSection(kind: kind, wallets: wallets)
        }
    }

    var walletName: String {
        wallets.first { $0.id == walletId }?.name ?? "財布"
    }

    var canSave: Bool {
        draft?.problems.isEmpty == true
    }

    var saveTitle: String {
        if isEditing {
            return "変更を保存"
        }

        return amount == 0 ? "金額を入れてください" : "\(AmountText.text(amount)) を記録する"
    }

    static func dateText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        let day = date.year == today.year
            ? "\(date.month)/\(date.day)"
            : "\(date.year)/\(date.month)/\(date.day)"

        let text = "\(day)（\(date.weekday.shortName)）"

        switch date {
        case today: return "今日 \(text)"
        case today.adding(days: -1): return "昨日 \(text)"
        default: return text
        }
    }

    func icon(for category: EntryCategory) -> Icon? {
        options?.icons[category.iconId]
    }

    func icon(for wallet: Wallet) -> Icon? {
        options?.icons[wallet.iconId]
    }

    func load() async {
        do {
            options = try await database.entryOptions()
            try await loadEntry()
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func press(_ key: Keypad.Key) {
        let next = switch key {
        case let .digit(value): amount * 10 + value
        case .doubleZero: amount * 100
        case .delete: amount / 10
        }

        if next <= Self.maxAmount {
            amount = next
        }
    }

    func select(_ type: Entry.Kind) {
        self.type = type

        if !categories.contains(where: { $0.id == categoryId }) {
            categoryId = categories.first?.id
        }
    }

    func save() async -> Bool {
        guard let draft else {
            return false
        }

        do {
            try await database.saveEntry(draft, editing: editingId, at: Date())
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    func delete() async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await database.deleteEntry(editingId)
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }
}

private extension EntryModel {
    static let maxAmount = 999_999_999

    var draft: EntryDraft? {
        guard let walletId else {
            return nil
        }

        return EntryDraft(
            type: type,
            amount: amount,
            date: date,
            categoryId: categoryId,
            walletId: walletId,
            memo: memo
        )
    }

    static func message(for error: any Error) -> String {
        switch error {
        case EntryDraft.Problem.amountNotPositive: "金額を入れてください"
        case EntryDraft.Problem.missingCategory: "カテゴリを選んでください"
        case AppDatabase.WriteError.entryNotFound: "記録が見つかりませんでした"
        default: "保存できませんでした"
        }
    }

    func categories(for type: Entry.Kind) -> [EntryCategory] {
        switch type {
        case .expense: options?.expenseCategories ?? []
        case .income: options?.incomeCategories ?? []
        case .transfer: []
        }
    }

    func loadEntry() async throws {
        guard let editingId else {
            categoryId = categories.first?.id
            walletId = wallets.first?.id
            return
        }

        guard let entry = try await database.entry(editingId) else {
            throw AppDatabase.WriteError.entryNotFound
        }

        type = entry.type
        amount = entry.amount
        date = entry.date
        categoryId = entry.categoryId
        walletId = entry.walletId
        memo = entry.memo ?? ""
    }
}

extension EntryModel.WalletSection: Identifiable {
    public var id: Wallet.Kind {
        kind
    }
}
