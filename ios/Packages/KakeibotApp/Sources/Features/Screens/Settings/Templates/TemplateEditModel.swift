import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class TemplateEditModel {
    public var name: String
    public var walletId: Wallet.ID?
    public var memo: String

    public var categoryId: EntryCategory.ID? {
        didSet {
            if categoryId != oldValue {
                tagId = nil
            }
        }
    }

    public private(set) var tagId: EntryTag.ID?
    public private(set) var type: Entry.Kind
    public private(set) var calculator: AmountCalculator
    public private(set) var options: EntryOptions?
    public private(set) var isHidden = false

    public internal(set) var errorNotice = ErrorNotice()

    private var baseline: EntryTemplateDraft?

    private let database: AppDatabase
    private let editingId: EntryTemplate.ID?

    public init(
        database: AppDatabase,
        type: Entry.Kind,
        editing id: EntryTemplate.ID? = nil
    ) {
        self.database = database
        self.editingId = id
        self.name = ""
        self.type = type
        self.calculator = AmountCalculator()
        self.memo = ""
    }

    public init(
        database: AppDatabase,
        draft: EntryTemplateDraft
    ) {
        self.database = database
        self.editingId = nil
        self.name = draft.name
        self.type = draft.type
        self.calculator = AmountCalculator(amount: draft.amount ?? 0)
        self.categoryId = draft.categoryId
        self.tagId = draft.tagId
        self.walletId = draft.walletId
        self.memo = draft.memo
    }
}

public extension TemplateEditModel {
    var isEditing: Bool {
        editingId != nil
    }

    var amount: Int? {
        calculator.amount > 0 ? calculator.amount : nil
    }

    var typeName: String {
        type == .income ? "収入" : "支出"
    }

    var walletTitle: String {
        type == .income ? "入金先" : "支払い元"
    }

    var draft: EntryTemplateDraft {
        EntryTemplateDraft(
            name: name,
            type: type,
            amount: amount,
            categoryId: categoryId,
            tagId: tagId,
            walletId: walletId,
            memo: memo
        )
    }

    var canSave: Bool {
        draft.problems.isEmpty
    }

    var saveTitle: String {
        SettingsSaveTitle.text(
            problem: draft.problems.first.map(message),
            isEditing: isEditing
        )
    }

    var isChanged: Bool {
        baseline.map { $0 != draft } ?? false
    }

    var categories: [EntryCategory] {
        switch type {
        case .expense: options?.expenseCategories ?? []
        case .income: options?.incomeCategories ?? []
        case .transfer: []
        }
    }

    var wallets: [Wallet] {
        options?.wallets ?? []
    }

    var selectedCategory: EntryCategory? {
        categories.first { $0.id == categoryId }
    }

    var selectedWallet: Wallet? {
        wallets.first { $0.id == walletId }
    }

    var tags: [EntryTag] {
        let tags = options?.tags ?? []

        return tags.filter { tag in
            tag.categoryId == categoryId
                && (tag.archivedAt == nil || tag.id == tagId)
        }
    }

    var selectedTag: EntryTag? {
        tags.first { $0.id == tagId }
    }

    func icon(for category: EntryCategory) -> Icon? {
        options?.icons[category.iconId]
    }

    func icon(for wallet: Wallet) -> Icon? {
        options?.icons[wallet.iconId]
    }

    func press(_ key: AmountCalculator.Key) {
        calculator.press(key)
    }

    func toggleTag(_ id: EntryTag.ID) {
        tagId = tagId == id ? nil : id
    }

    func load() async {
        do {
            options = try await database.entryOptions()
            try await loadTemplate()

            if categoryId == nil {
                categoryId = categories.first?.id
            }

            if walletId == nil {
                walletId = wallets.first?.id
            }

            baseline = draft
        } catch is CancellationError {
            return
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func save() async -> EntryTemplate? {
        if let problem = draft.problems.first {
            errorNotice.show(message(for: problem))
            return nil
        }

        do {
            return try await database.saveTemplate(
                draft,
                editing: editingId,
                at: Date()
            )
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return nil
        }
    }

    func delete() async -> Deletion? {
        guard let editingId else {
            return nil
        }

        do {
            return try await database.deleteTemplate(editingId)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return nil
        }
    }

    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await database.setTemplateHidden(
                editingId,
                isHidden: isHidden,
                at: Date()
            )

            self.isHidden = isHidden
            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return false
        }
    }
}

private extension TemplateEditModel {
    static let loadFailedMessage = "テンプレートを読めませんでした"
    static let saveFailedMessage = "保存できませんでした"

    func message(for problem: EntryTemplateDraft.Problem) -> String {
        switch problem {
        case .emptyName: "名前を入れてください"
        case .missingCategory: "カテゴリを選んでください"
        case .missingWallet: "\(walletTitle)を選んでください"
        case .amountNotPositive, .transfer: Self.saveFailedMessage
        }
    }

    func loadTemplate() async throws {
        guard let editingId else {
            return
        }

        let templates = try await database.templates(includingHidden: true)
        let template = templates.first { $0.id == editingId }

        guard let template else {
            throw AppDatabase.TemplateWriteError.templateNotFound
        }

        isHidden = template.archivedAt != nil

        let draft = EntryTemplateDraft(template)
        name = draft.name
        type = draft.type
        calculator = AmountCalculator(amount: draft.amount ?? 0)
        categoryId = draft.categoryId
        tagId = draft.tagId
        walletId = draft.walletId
        memo = draft.memo
    }
}
