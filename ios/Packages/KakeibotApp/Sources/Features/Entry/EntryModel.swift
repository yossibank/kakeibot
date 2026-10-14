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
    public private(set) var calculator = AmountCalculator()
    public private(set) var options: EntryOptions?
    public private(set) var recentMemos: [String] = []
    public private(set) var errorMessage: String?

    private var baseline: Snapshot?

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
    enum CategoryCell: Hashable {
        case category(EntryCategory)
        case add

        public var categoryId: EntryCategory.ID? {
            if case let .category(category) = self {
                category.id
            } else {
                nil
            }
        }
    }

    struct WalletSection {
        public let kind: Wallet.Kind
        public let wallets: [Wallet]
    }

    static let categoriesPerPage = 12

    var isEditing: Bool {
        editingId != nil
    }

    var isLoaded: Bool {
        options != nil
    }

    var isChanged: Bool {
        baseline.map { $0 != snapshot } ?? false
    }

    var amount: Int {
        calculator.amount
    }

    var expressionText: String? {
        if let note = calculator.taxNote {
            return "\(Self.number(note.base)) の税込み \(note.rate.rawValue)%"
        }

        guard calculator.hasOperation else {
            return nil
        }

        let parts = calculator.tokens.map { token in
            switch token {
            case let .number(number): Self.number(number)
            case let .operation(operation): operation.symbol
            }
        }

        return parts.joined(separator: " ")
    }

    var categories: [EntryCategory] {
        categories(for: type)
    }

    var categoryPages: [[CategoryCell]] {
        let cells = categories.map(CategoryCell.category) + [.add]
        let size = Self.categoriesPerPage

        return stride(from: 0, to: cells.count, by: size).map { start in
            Array(cells[start..<min(start + size, cells.count)])
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
            return wallets.isEmpty
                ? nil
                : WalletSection(kind: kind, wallets: wallets)
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
            let limit = Self.recentMemoLimit
            recentMemos = try await database.recentMemos(limit: limit)
            try await loadEntry()
            baseline = snapshot
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func newCategoryModel() -> CategoryEditModel {
        let kind: EntryCategory.Kind = type == .income ? .income : .expense
        return CategoryEditModel(database: database, kind: kind)
    }

    func addCategory(_ category: EntryCategory) async {
        do {
            options = try await database.entryOptions()
            categoryId = category.id
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
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
    struct Snapshot: Equatable {
        let type: Entry.Kind
        let calculator: AmountCalculator
        let date: LocalDate
        let categoryId: EntryCategory.ID?
        let walletId: Wallet.ID?
        let memo: String
    }

    var snapshot: Snapshot {
        Snapshot(
            type: type,
            calculator: calculator,
            date: date,
            categoryId: categoryId,
            walletId: walletId,
            memo: memo
        )
    }

    static let recentMemoLimit = 6
    static let numberLocale = Locale(identifier: "ja_JP")

    static func number(_ value: Int) -> String {
        value.formatted(.number.locale(numberLocale))
    }

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
        calculator = AmountCalculator(amount: entry.amount)
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
