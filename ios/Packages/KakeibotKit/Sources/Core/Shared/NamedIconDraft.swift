import Foundation

public protocol NamedIconDraft: Draft where Problem == DraftProblem {
    var name: String { get }
    var mark: IconDraft.Mark { get }
    var color: String { get }
}

public extension NamedIconDraft {
    var icon: IconDraft {
        IconDraft(mark: mark, color: color)
    }

    var namedIconProblems: [DraftProblem] {
        let nameProblems: [DraftProblem] = trimmedName.isEmpty ? [.emptyName] : []
        return nameProblems + icon.problems
    }

    func newIcon(at now: Date) throws -> Icon {
        try validate()
        return try icon.newIcon(at: now)
    }

    func applied(
        to icon: Icon,
        at now: Date
    ) throws -> Icon {
        try validate()
        return try self.icon.applied(to: icon, at: now)
    }
}

extension NamedIconDraft {
    var trimmedName: String {
        name.trimmed
    }
}
