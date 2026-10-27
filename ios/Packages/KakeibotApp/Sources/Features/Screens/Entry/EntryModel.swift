import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class EntryModel {
    public var date: LocalDate {
        didSet {
            if date != oldValue {
                billMonth = nil
            }
        }
    }

    public var walletId: Wallet.ID? {
        didSet {
            if walletId != oldValue {
                billMonth = nil
            }
        }
    }

    public var categoryId: EntryCategory.ID? {
        didSet {
            if categoryId != oldValue {
                tagId = nil
            }
        }
    }

    public var toWalletId: Wallet.ID?
    public var memo = ""

    public private(set) var tagId: EntryTag.ID?
    public private(set) var billMonth: YearMonth?
    public private(set) var type: Entry.Kind
    public private(set) var calculator = AmountCalculator()
    public private(set) var feeCalculator = AmountCalculator()
    public private(set) var keypadTarget: KeypadTarget = .amount
    public private(set) var options: EntryOptions?
    public private(set) var recentMemos: [String] = []
    public private(set) var balances: [Wallet.ID: Int] = [:]
    public private(set) var weekStart: Weekday = .sunday

    public internal(set) var errorNotice = ErrorNotice()

    let database: AppDatabase

    private var baseline: Snapshot?
    private var original: Entry?
    private var originalFee: Entry?
    private var allTemplates: [EntryTemplate] = []
    private var categoryByType: [Entry.Kind: EntryCategory.ID] = [:]
    private var appliedTemplateId: EntryTemplate.ID?
    private var cardBills: [Recurring] = []
    private var history: EntryList?
    private var budgets: [Budget] = []
    private var monthStartDay: MonthStartDay = .first
    private var editingId: Entry.ID?

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
    enum KeypadTarget: Hashable {
        case amount
        case fee
    }

    enum CategoryCell: Hashable {
        case category(EntryCategory)
        case add
        case edit

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

    struct TransferRoute: Hashable {
        public let walletId: Wallet.ID
        public let toWalletId: Wallet.ID
    }

    struct BalanceLine: Equatable {
        public let title: String
        public let amount: Int
    }

    struct BillChoice: Identifiable, Hashable {
        public let date: LocalDate
        public let title: String
        public let period: ClosedRange<LocalDate>?

        public var id: LocalDate {
            date
        }
    }

    static let categoriesPerPage = 15
    static let recentTransferLimit = 3
    static let frequentRouteLimit = 6

    static let destinationTitle = "振替先"

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

    var fee: Int {
        type == .transfer ? feeCalculator.amount : 0
    }

    var activeCalculator: AmountCalculator {
        keypadTarget == .fee ? feeCalculator : calculator
    }

    var feeChoices: [Int] {
        let used = (history?.days ?? [])
            .flatMap(\.entries)
            .filter { $0.transferId != nil }
            .sorted { $0.createdAt > $1.createdAt }
            .map(\.amount)

        var seen: Set<Int> = []

        let ordered = (used + FeeChoiceRow.defaultChoices).filter { seen.insert($0).inserted }

        return Array(ordered.prefix(FeeChoiceRow.defaultChoices.count))
    }

    var expressionText: String? {
        let calculator = activeCalculator

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
        let cells = categories.map(CategoryCell.category) + [.add, .edit]
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

    var billText: String? {
        guard
            billMonth != nil,
            let date = selectedBillDate
        else {
            return nil
        }

        return "\(date.month)/\(date.day)払い"
    }

    var billChoices: [BillChoice] {
        guard
            type != .transfer,
            let walletId,
            let bill = cardBills.first(where: { $0.toWalletId == walletId })
        else {
            return []
        }

        let dates = bill.billDates(for: date, count: Self.billTitles.count)

        return zip(dates, Self.billTitles).map { date, title in
            BillChoice(
                date: date,
                title: title,
                period: bill.billingPeriod(paidOn: date)
            )
        }
    }

    var selectedBillDate: LocalDate? {
        let choices = billChoices
        let chosen = choices.first { $0.date.yearMonth == billMonth }

        return chosen?.date ?? choices.first?.date
    }

    var isUsualWallet: Bool {
        type == .transfer || walletId == wallets.first?.id
    }

    var budgetUsage: BudgetUsage? {
        guard type == .expense else {
            return nil
        }

        return monthOverview.budgetUsage
    }

    var monthTotalText: String? {
        guard
            type != .transfer,
            budgetUsage == nil
        else {
            return nil
        }

        let overview = monthOverview
        let month = history?.days.filter { overview.period.contains($0.date) } ?? []

        let entries = month
            .flatMap(\.entries)
            .filter { $0.type == type && (categoryId == nil || $0.categoryId == categoryId) }

        let current = entries.reduce(0) { $0 + $1.amount }
        let title = "今月の\(selectedCategory?.name ?? typeName)"

        let previous = entries.first { $0.id == original?.id }?.amount ?? 0
        let added = overview.period.contains(date) ? amount : 0
        let after = current - previous + added

        guard after != current else {
            return "\(title) \(AmountText.text(current))"
        }

        return "\(title) \(AmountText.text(current)) → \(AmountText.text(after))"
    }

    var transferProgress: Double? {
        guard
            type == .transfer,
            let balance = wallet(walletId).flatMap(balance(of:)),
            balance > 0
        else {
            return nil
        }

        return min(max(Double(amount + fee) / Double(balance), 0), 1)
    }

    var recentTransfers: [Entry] {
        var seen: Set<String> = []

        let unique = manualTransfers.filter { entry in
            let route = "\(entry.walletId)>\(String(describing: entry.toWalletId))"
            let key = "\(route)>\(entry.amount)>\(fee(of: entry))"
            return seen.insert(key).inserted
        }

        return Array(unique.prefix(Self.recentTransferLimit))
    }

    var frequentRoutes: [TransferRoute] {
        let routes = manualTransfers.compactMap(Self.route(of:))
        let counts = Dictionary(routes.map { ($0, 1) }, uniquingKeysWith: +)

        var seen: Set<TransferRoute> = []

        let ordered = routes.filter { seen.insert($0).inserted }

        let sorted = ordered.enumerated().sorted { lhs, rhs in
            let left = counts[lhs.element, default: 0]
            let right = counts[rhs.element, default: 0]
            return left == right ? lhs.offset < rhs.offset : left > right
        }

        return sorted.prefix(Self.frequentRouteLimit).map(\.element)
    }

    var routeText: String? {
        guard
            let source = wallet(walletId),
            let destination = wallet(toWalletId)
        else {
            return nil
        }

        return "\(source.name) → \(destination.name)"
    }

    var sourceBalanceText: String? {
        guard
            type == .transfer,
            let source = wallet(walletId),
            let line = afterLine(of: source, isSource: true) ?? currentLine(of: source)
        else {
            return nil
        }

        return "\(source.name) \(line.title) \(AmountText.text(line.amount))"
    }

    var walletTitle: String {
        switch type {
        case .expense: "支払い元"
        case .income: "入金先"
        case .transfer: "振替元"
        }
    }

    var memoPrompt: String {
        switch type {
        case .expense: "店名や買ったもの"
        case .income: "どこから入ったか"
        case .transfer: "何のための移動か"
        }
    }

    var memoHint: String {
        switch type {
        case .expense: "店名など"
        case .income: "入金元など"
        case .transfer: "用途など"
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

    var saveSubject: String? {
        guard
            !isEditing,
            amount > 0,
            type != .transfer
        else {
            return nil
        }

        return selectedCategory?.name
    }

    var isOverSourceBalance: Bool {
        guard
            type == .transfer,
            amount > 0
        else {
            return false
        }

        guard let balance = wallet(walletId).flatMap(balance(of:)) else {
            return false
        }

        return amount + fee > balance
    }

    var loanRemaining: Int? {
        guard
            type == .transfer,
            let wallet = wallet(toWalletId),
            wallet.kind == .loan,
            let balance = balance(of: wallet),
            balance < 0
        else {
            return nil
        }

        return -balance
    }

    var monthOverview: MonthOverview {
        MonthOverview(
            list: history,
            budgets: budgets,
            recurrings: [],
            monthStartDay: monthStartDay,
            today: Self.today
        )
    }

    static func dayText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        date.year == today.year
            ? "\(date.month)/\(date.day)"
            : "\(date.year)/\(date.month)/\(date.day)"
    }

    static func dateText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        let day = dayText(for: date, today: today)
        let text = "\(day)（\(date.weekday.shortName)）"

        switch date {
        case today: return "今日 \(text)"
        case today.adding(days: -1): return "昨日 \(text)"
        default: return text
        }
    }

    static func dateTitle(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        let days = date.days(until: today)

        switch days {
        case 0, 1: return "日付"
        case 2...: return "日付・\(days)日前"
        default: return "日付・\(-days)日後"
        }
    }

    func saveDetail(today: LocalDate) -> String? {
        if type == .transfer, fee > 0 {
            return "手数料 \(AmountText.text(fee)) も記録"
        }

        guard
            !isEditing,
            canSave,
            type != .transfer,
            let wallet = wallet(walletId)
        else {
            return nil
        }

        let day = switch date {
        case today: "今日"
        case today.adding(days: -1): "昨日"
        default: Self.dayText(for: date, today: today)
        }

        let direction = type == .income ? "へ" : "から"

        return "\(day)・\(wallet.name)\(direction)"
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

    func balanceText(of wallet: Wallet) -> String? {
        guard let balance = balance(of: wallet) else {
            return nil
        }

        switch wallet.kind.role {
        case .loan: return "残り \(AmountText.text(max(-balance, 0)))"
        case .investment: return "評価額 \(AmountText.text(balance))"
        case .onHand, .card: return "残高 \(AmountText.text(balance))"
        }
    }

    func currentLine(of wallet: Wallet) -> BalanceLine? {
        guard let balance = balance(of: wallet) else {
            return nil
        }

        switch wallet.kind.role {
        case .loan: return BalanceLine(title: "今の残り", amount: max(-balance, 0))
        case .investment: return BalanceLine(title: "今の評価額", amount: balance)
        case .onHand, .card: return BalanceLine(title: "残高", amount: balance)
        }
    }

    func afterLine(
        of wallet: Wallet,
        isSource: Bool
    ) -> BalanceLine? {
        guard
            type == .transfer,
            amount > 0,
            let balance = balance(of: wallet)
        else {
            return nil
        }

        let after = isSource ? balance - amount - fee : balance + amount

        switch (wallet.kind.role, isSource) {
        case (.loan, false): return BalanceLine(title: "返済後", amount: max(-after, 0))
        case (.investment, false): return BalanceLine(title: "積立後", amount: after)
        case (.loan, true): return BalanceLine(title: "振替後", amount: max(-after, 0))
        default: return BalanceLine(title: "振替後", amount: after)
        }
    }

    func payOffLoan() {
        guard let loanRemaining else {
            return
        }

        calculator = AmountCalculator(amount: loanRemaining)
    }

    func icon(for template: EntryTemplate) -> Icon? {
        let categories = categories(for: template.type)
        let category = categories.first { $0.id == template.categoryId }
        return category.flatMap { options?.icons[$0.iconId] }
    }

    func load() async {
        do {
            let limit = Self.recentMemoLimit

            options = try await database.entryOptions()

            recentMemos = try await database.recentMemos(limit: limit)

            allTemplates = try await database.templates()

            cardBills = try await database.recurrings()
                .filter { $0.type == .transfer && $0.closingDay != nil }

            weekStart = try await database.setting(.weekStart)

            monthStartDay = try await database.setting(.monthStartDay)

            budgets = try await database.budgets()

            try await loadEntry()

            try await loadBalances()

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

    func newWalletModel() -> WalletEditModel {
        WalletEditModel(database: database)
    }

    func editWalletModel(_ id: Wallet.ID) -> WalletEditModel {
        WalletEditModel(database: database, editing: id)
    }

    func reloadWallets() async {
        do {
            options = try await database.entryOptions()

            if !wallets.contains(where: { $0.id == walletId }) {
                walletId = wallets.first { $0.id != toWalletId }?.id ?? wallets.first?.id
            }

            if type == .transfer {
                if !wallets.contains(where: { $0.id == toWalletId }) {
                    toWalletId = nil
                }

                chooseDestination()
            }

            try await loadBalances()
        } catch {
            report(error)
        }
    }

    func editCategoryModel(_ category: EntryCategory) -> CategoryEditModel {
        CategoryEditModel(
            database: database,
            kind: category.kind,
            editing: category.id
        )
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await database.restore(deletion)
            await reloadCategories()
            await reloadTemplates()
        } catch {
            errorNotice.show(Self.restoreFailedMessage)
        }
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

    func press(_ key: AmountCalculator.Key) {
        switch keypadTarget {
        case .amount: calculator.press(key)
        case .fee: feeCalculator.press(key)
        }
    }

    func enter(_ target: KeypadTarget) {
        keypadTarget = type == .transfer ? target : .amount
    }

    func setFee(_ amount: Int) {
        feeCalculator = AmountCalculator(amount: amount)
    }

    func fee(of transfer: Entry) -> Int {
        let entries = history?.days.flatMap(\.entries) ?? []
        return entries.first { $0.transferId == transfer.id }?.amount ?? 0
    }

    func toggleTag(_ id: EntryTag.ID) {
        tagId = tagId == id ? nil : id
    }

    func selectBill(_ date: LocalDate) {
        let isUsual = date == billChoices.first?.date
        billMonth = isUsual ? nil : date.yearMonth
    }

    func applyRoute(_ route: TransferRoute) {
        walletId = route.walletId
        toWalletId = route.toWalletId
    }

    func applyTransfer(_ entry: Entry) {
        walletId = entry.walletId
        toWalletId = entry.toWalletId
        calculator = AmountCalculator(amount: entry.amount)
        feeCalculator = AmountCalculator(amount: fee(of: entry))
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
        keypadTarget = .amount

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

            let fee = try await database.fee(of: entry.id)
            let title = label(for: entry)

            let kind: EntryChange.Kind = if let original {
                .edited(previous: original, previousFee: originalFee)
            } else {
                .recorded
            }

            return EntryChange(
                kind: kind,
                entry: entry,
                label: title,
                fee: fee
            )
        } catch {
            report(error)
            return nil
        }
    }

    func startNext() async {
        calculator = AmountCalculator()
        feeCalculator = AmountCalculator()
        keypadTarget = .amount
        memo = ""
        tagId = nil
        billMonth = nil
        appliedTemplateId = nil

        do {
            try await loadBalances()
        } catch {
            report(error)
        }

        baseline = snapshot
    }

    func delete() async -> EntryChange? {
        guard let original else {
            return nil
        }

        do {
            let deleted = try await database.deleteEntry(original.id)
            let title = label(for: original)

            return EntryChange(
                kind: .deleted,
                entry: original,
                label: title,
                fee: deleted.first { $0.transferId == original.id }
            )
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
        let feeCalculator: AmountCalculator
        let date: LocalDate
        let categoryId: EntryCategory.ID?
        let tagId: EntryTag.ID?
        let walletId: Wallet.ID?
        let toWalletId: Wallet.ID?
        let memo: String
        let billMonth: YearMonth?
    }

    static let restoreFailedMessage = "元に戻せませんでした"
    static let recentMemoLimit = 6
    static let billTitles = ["いつもどおり", "次に回す", "2 回先"]
    static let numberLocale = Locale(identifier: "ja_JP")

    static var today: LocalDate {
        LocalDate(Date(), in: .current)
    }

    var manualTransfers: [Entry] {
        (history?.days ?? [])
            .flatMap(\.entries)
            .filter { entry in
                entry.type == .transfer
                    && entry.recurringId == nil
                    && entry.id != editingId
                    && wallet(entry.walletId) != nil
                    && wallet(entry.toWalletId) != nil
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var snapshot: Snapshot {
        Snapshot(
            type: type,
            calculator: calculator,
            feeCalculator: feeCalculator,
            date: date,
            categoryId: categoryId,
            tagId: tagId,
            walletId: walletId,
            toWalletId: toWalletId,
            memo: memo,
            billMonth: billMonth
        )
    }

    var draft: EntryDraft? {
        guard let walletId else {
            return nil
        }

        let templateId = allTemplates
            .first { $0.id == appliedTemplateId && $0.type == type }?
            .id

        let billMonth = billChoices.isEmpty ? nil : billMonth

        return EntryDraft(
            type: type,
            amount: amount,
            date: date,
            categoryId: categoryId,
            tagId: tagId,
            templateId: templateId,
            walletId: walletId,
            toWalletId: toWalletId,
            memo: memo,
            billMonth: billMonth,
            fee: fee
        )
    }

    static func route(of entry: Entry) -> TransferRoute? {
        entry.toWalletId.map { TransferRoute(walletId: entry.walletId, toWalletId: $0) }
    }

    static func number(_ value: Int) -> String {
        value.formatted(.number.locale(numberLocale))
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

    func report(_ error: any Error) {
        guard !(error is CancellationError) else {
            return
        }

        errorNotice.show(Self.message(for: error))
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

        guard var entry = try await database.entry(editingId) else {
            throw AppDatabase.WriteError.entryNotFound
        }

        if let transferId = entry.transferId,
           let transfer = try await database.entry(transferId) {
            entry = transfer
            self.editingId = transferId
        }

        originalFee = try await database.fee(of: entry.id)
        original = entry
        type = entry.type
        calculator = AmountCalculator(amount: entry.amount)
        date = entry.date
        categoryId = entry.categoryId
        tagId = entry.tagId
        walletId = entry.walletId
        toWalletId = entry.toWalletId
        memo = entry.memo ?? ""
        appliedTemplateId = entry.templateId
        billMonth = entry.billMonth
        feeCalculator = AmountCalculator(amount: originalFee?.amount ?? 0)
    }

    func loadBalances() async throws {
        let list = try await database.entryList()

        history = list

        let entries = list.days
            .flatMap(\.entries)
            .filter { $0.id != editingId && !isOwnFee($0) }

        let valuations = list.valuations

        let pairs = wallets.map { wallet in
            (wallet.id, wallet.balance(with: entries, valuations: valuations))
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

    func isOwnFee(_ entry: Entry) -> Bool {
        guard let editingId else {
            return false
        }

        return entry.transferId == editingId
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
