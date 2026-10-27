import Core

public struct SavedEntry: Hashable, Sendable {
    public let entry: Entry
    public let clearedNoSpendDays: [NoSpendDay]
}
