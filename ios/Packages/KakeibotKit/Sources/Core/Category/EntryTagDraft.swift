import Foundation

public struct EntryTagDraft: Hashable, Sendable {
    public var id: EntryTag.ID?
    public var name: String

    public init(
        id: EntryTag.ID? = nil,
        name: String
    ) {
        self.id = id
        self.name = name
    }
}

public extension EntryTagDraft {
    enum Problem: String, CaseIterable, Codable, Error, Sendable {
        case emptyName
        case nameTooLong
    }

    static let maxNameLength = 8

    var problems: [Problem] {
        if trimmedName.isEmpty {
            return [.emptyName]
        }

        return trimmedName.count > Self.maxNameLength ? [.nameTooLong] : []
    }

    init(_ tag: EntryTag) {
        self.init(id: tag.id, name: tag.name)
    }

    func newTag(
        categoryId: EntryCategory.ID,
        sortOrder: Int,
        at now: Date
    ) throws -> EntryTag {
        try validate()

        return EntryTag(
            categoryId: categoryId,
            name: trimmedName,
            sortOrder: sortOrder,
            createdAt: now,
            updatedAt: now
        )
    }

    func applied(
        to tag: EntryTag,
        sortOrder: Int,
        at now: Date
    ) throws -> EntryTag {
        try validate()

        var updated = tag
        updated.name = trimmedName
        updated.sortOrder = sortOrder
        updated.archivedAt = nil
        updated.updatedAt = now
        return updated
    }
}

private extension EntryTagDraft {
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func validate() throws {
        if let problem = problems.first {
            throw problem
        }
    }
}
