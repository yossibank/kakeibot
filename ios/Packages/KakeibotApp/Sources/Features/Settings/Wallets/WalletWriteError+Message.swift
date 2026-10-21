import Store

extension AppDatabase.WalletWriteError {
    static let lastShownMessage = "最後の 1 つの口座は非表示にできません"
    static let lastShownDeleteMessage = "最後の 1 つの口座は削除できません"
    static let hasEntriesMessage = "記録があるので削除できません。非表示にできます"
    static let deleteFailedMessage = "削除できませんでした"

    static func deleteMessage(for error: any Error) -> String {
        switch error as? Self {
        case .hasEntries: hasEntriesMessage
        case .lastShownWallet: lastShownDeleteMessage
        default: deleteFailedMessage
        }
    }
}
