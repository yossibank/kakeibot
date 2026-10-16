import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class EntryModel {
    public var date: LocalDate
    public var walletId: Wallet.ID?
    public var toWalletId: Wallet.ID?
    public var memo = ""

    public var categoryId: EntryCategory.ID? {
        didSet {
            if categoryId != oldValue {
                tagId = nil
            }
        }
    }

    public private(set) var tagId: EntryTag.ID?
    public private(set) var type: Entry.Kind
    public private(set) var calculator = AmountCalculator()
    public private(set) var options: EntryOptions?
    public private(set) var recentMemos: [String] = []
    public private(set) var balances: [Wallet.ID: Int] = [:]
    public private(set) var errorMessage: String?
    public private(set) var errorCount = 0

    private var baseline: Snapshot?
    private var original: Entry?
    private var allTemplates: [EntryTemplate] = []
    private var categoryByType: [Entry.Kind: EntryCategory.ID] = [:]
    private var appliedTemplateId: EntryTemplate.ID?

    private let database: AppDatabase
    private let editingId: Entry.ID?
    private let startingTemplate: EntryTemplate?

    public init(
        database: AppDatabase,
        editing id: Entry.ID? = nil,
        date: LocalDate,
        type: Entry.Kind = .expense,
        template: EntryTemplate? = nil
    ) {
        self.database = database
        self.editingId = id
        self.date = date
        self.type = type
        self.startingTemplate = template
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

    static let categoriesPerPage = 15

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

    var templates: [EntryTemplate] {
        allTemplates.filter { $0.type == type }
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

    var tags: [EntryTag] {
        let tags = options?.tags ?? []

        return tags.filter { tag in
            tag.categoryId == categoryId
                && (tag.archivedAt == nil || tag.id == tagId)
        }
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
        wallet(walletId)?.name ?? walletTitle
    }

    var walletTitle: String {
        switch type {
        case .expense: "支払い元"
        case .income: "入金先"
        case .transfer: "振替元"
        }
    }

    var typeName: String {
        switch type {
        case .expense: "支出"
        case .income: "収入"
        case .transfer: "振替"
        }
    }

    var canSave: Bool {
        draft?.problems.isEmpty == true
    }

    var saveTitle: String {
        if isEditing {
            return "変更を保存"
        }

        guard amount > 0 else {
            return "金額を入れてください"
        }

        if type == .transfer, toWalletId == nil {
            return "\(Self.destinationTitle)を選んでください"
        }

        let action = type == .transfer ? "振り替える" : "記録する"
        return "\(AmountText.text(amount)) を\(action)"
    }

    static let destinationTitle = "振替先"

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

    func wallet(_ id: Wallet.ID?) -> Wallet? {
        wallets.first { $0.id == id }
    }

    func balance(of wallet: Wallet) -> Int? {
        balances[wallet.id]
    }

    func icon(for template: EntryTemplate) -> Icon? {
        let categories = categories(for: template.type)
        let category = categories.first { $0.id == template.categoryId }
        return category.flatMap { options?.icons[$0.iconId] }
    }

    func load() async {
        do {
            options = try await database.entryOptions()
            let limit = Self.recentMemoLimit
            recentMemos = try await database.recentMemos(limit: limit)
            allTemplates = try await database.templates()
            try await loadBalances()
            try await loadEntry()

            if let startingTemplate {
                apply(startingTemplate)
            }

            baseline = snapshot
        } catch {
            report(error)
        }
    }

    func isApplied(_ template: EntryTemplate) -> Bool {
        let amountMatches = template.amount.map { $0 == amount } ?? true

        return template.id == appliedTemplateId
            && template.type == type
            && template.categoryId == categoryId
            && template.tagId == tagId
            && template.walletId == walletId
            && (template.memo ?? "") == memo
            && amountMatches
    }

    func apply(_ template: EntryTemplate) {
        select(template.type)
        categoryId = template.categoryId
        tagId = template.tagId
        walletId = template.walletId
        memo = template.memo ?? ""
        calculator = AmountCalculator(amount: template.amount ?? 0)
        appliedTemplateId = template.id
    }

    func reloadTemplates() async {
        do {
            allTemplates = try await database.templates()
        } catch {
            report(error)
        }
    }

    func newTemplateModel() -> TemplateEditModel {
        let templateType: Entry.Kind = type == .income ? .income : .expense

        let draft = EntryTemplateDraft(
            name: "",
            type: templateType,
            amount: amount > 0 ? amount : nil,
            categoryId: categoryId,
            tagId: tagId,
            walletId: walletId,
            memo: memo
        )

        return TemplateEditModel(database: database, draft: draft)
    }

    func newCategoryModel() -> CategoryEditModel {
        let kind: EntryCategory.Kind = type == .income ? .income : .expense
        return CategoryEditModel(database: database, kind: kind)
    }

    func editCategoryModel(_ category: EntryCategory) -> CategoryEditModel {
        CategoryEditModel(
            database: database,
            kind: category.kind,
            editing: category.id
        )
    }

    func reloadCategories(selecting id: EntryCategory.ID? = nil) async {
        do {
            options = try await database.entryOptions()

            if let id {
                categoryId = id
            } else if !categories.contains(where: { $0.id == categoryId }) {
                categoryId = categories.first?.id
            }
        } catch {
            report(error)
        }
    }

    func hideCategory(_ category: EntryCategory) async {
        do {
            try await database.setCategoryHidden(
                category.id,
                isHidden: true,
                at: Date()
            )

            await reloadCategories()
        } catch {
            report(error)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }

    func toggleTag(_ id: EntryTag.ID) {
        tagId = tagId == id ? nil : id
    }

    func swapWallets() {
        let source = walletId
        walletId = toWalletId
        toWalletId = source
    }

    func select(_ type: Entry.Kind) {
        guard type != self.type else {
            return
        }

        categoryByType[self.type] = categoryId
        self.type = type

        let remembered = categoryByType[type]

        if categories.contains(where: { $0.id == remembered }) {
            categoryId = remembered
        } else if !categories.contains(where: { $0.id == categoryId }) {
            categoryId = categories.first?.id
        }

        if type == .transfer {
            chooseDestination()
        }
    }

    func save() async -> EntryChange? {
        guard let draft else {
            return nil
        }

        do {
            let entry = try await database.saveEntry(
                draft,
                editing: editingId,
                at: Date()
            )

            let title = label(for: entry)

            let kind: EntryChange.Kind = if let original {
                .edited(previous: original)
            } else {
                .recorded
            }

            return EntryChange(kind: kind, entry: entry, label: title)
        } catch {
            report(error)
            return nil
        }
    }

    func delete() async -> EntryChange? {
        guard let original else {
            return nil
        }

        do {
            try await database.deleteEntry(original.id)
            let title = label(for: original)

            return EntryChange(kind: .deleted, entry: original, label: title)
        } catch {
            report(error)
            return nil
        }
    }
}

private extension EntryModel {
    struct Snapshot: Equatable {
        let type: Entry.Kind
        let calculator: AmountCalculator
        let date: LocalDate
        let categoryId: EntryCategory.ID?
        let tagId: EntryTag.ID?
        let walletId: Wallet.ID?
        let toWalletId: Wallet.ID?
        let memo: String
    }

    var snapshot: Snapshot {
        Snapshot(
            type: type,
            calculator: calculator,
            date: date,
            categoryId: categoryId,
            tagId: tagId,
            walletId: walletId,
            toWalletId: toWalletId,
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
            tagId: tagId,
            walletId: walletId,
            toWalletId: toWalletId,
            memo: memo
        )
    }

    func report(_ error: any Error) {
        guard !(error is CancellationError) else {
            return
        }

        errorMessage = Self.message(for: error)
        errorCount += 1
    }

    static func message(for error: any Error) -> String {
        switch error {
        case EntryDraft.Problem.amountNotPositive: "金額を入れてください"
        case EntryDraft.Problem.missingCategory: "カテゴリを選んでください"
        case EntryDraft.Problem.missingDestination: "振替先を選んでください"
        case EntryDraft.Problem.sameWallet: "振替元と振替先を別にしてください"
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

            if type == .transfer {
                chooseDestination()
            }

            return
        }

        guard let entry = try await database.entry(editingId) else {
            throw AppDatabase.WriteError.entryNotFound
        }

        original = entry
        type = entry.type
        calculator = AmountCalculator(amount: entry.amount)
        date = entry.date
        categoryId = entry.categoryId
        tagId = entry.tagId
        walletId = entry.walletId
        toWalletId = entry.toWalletId
        memo = entry.memo ?? ""
    }

    func loadBalances() async throws {
        let list = try await database.entryList()
        let entries = list.days.flatMap(\.entries)

        let pairs = wallets.map { wallet in
            (wallet.id, wallet.balance(with: entries))
        }

        balances = Dictionary(uniqueKeysWithValues: pairs)
    }

    func label(for entry: Entry) -> String {
        let categories = categories(for: entry.type)

        return EntryChange.label(for: entry) { id in
            categories.first { $0.id == id }
        } wallet: { id in
            wallet(id)
        }
    }

    func chooseDestination() {
        guard toWalletId == nil || toWalletId == walletId else {
            return
        }

        toWalletId = wallets.first { $0.id != walletId }?.id
    }
}

extension EntryModel.WalletSection: Identifiable {
    public var id: Wallet.Kind {
        kind
    }
}
