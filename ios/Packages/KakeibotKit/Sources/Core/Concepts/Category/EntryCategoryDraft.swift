import Foundation

public struct EntryCategoryDraft: Draft, Hashable, Sendable {
    public var kind: EntryCategory.Kind
    public var name: String
    public var mark: Mark
    public var color: String

    public init(
        kind: EntryCategory.Kind,
        name: String,
        mark: Mark,
        color: String
    ) {
        self.kind = kind
        self.name = name
        self.mark = mark
        self.color = color
    }

    public init(
        _ category: EntryCategory,
        icon: Icon
    ) {
        self.init(kind: category.kind, name: category.name, mark: icon.mark, color: icon.color)
    }
}

public extension EntryCategoryDraft {
    typealias Mark = IconDraft.Mark
    typealias Problem = DraftProblem

    static let maxTextLength = IconDraft.maxTextLength

    var icon: IconDraft {
        IconDraft(mark: mark, color: color)
    }

    var problems: [Problem] {
        let nameProblems: [Problem] = trimmedName.isEmpty ? [.emptyName] : []
        return nameProblems + icon.problems
    }

    func newIcon(at now: Date) throws -> Icon {
        try validate()
        return try icon.newIcon(at: now)
    }

    func newCategory(
        iconId: Icon.ID,
        sortOrder: Int,
        at now: Date
    ) throws -> EntryCategory {
        try validate()

        return EntryCategory(
            kind: kind,
            name: trimmedName,
            iconId: iconId,
            sortOrder: sortOrder,
            createdAt: now,
            updatedAt: now
        )
    }

    func applied(
        to icon: Icon,
        at now: Date
    ) throws -> Icon {
        try validate()
        return try self.icon.applied(to: icon, at: now)
    }

    func applied(
        to category: EntryCategory,
        at now: Date
    ) throws -> EntryCategory {
        try validate()

        var updated = category

        updated.name = trimmedName
        updated.updatedAt = now

        return updated
    }
}

private extension EntryCategoryDraft {
    var trimmedName: String {
        name.trimmed
    }
}
