public enum EntryBatchChange: Hashable, Sendable {
    case category(EntryCategory.ID)
    case wallet(Wallet.ID)
}
