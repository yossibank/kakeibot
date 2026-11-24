import Core
import Observation

public extension WalletEditModel {
    @MainActor
    @Observable
    final class Input: SettingsEditHidingInput {
        public internal(set) var balance = 0
        public internal(set) var totalBalance = 0
        public internal(set) var valuations: [Valuation] = []
        public internal(set) var isHidden = false
        public internal(set) var payment: Recurring?
        public internal(set) var recordedKind: Wallet.Kind?
        public internal(set) var hasValuations = false
        public internal(set) var hasEntries = false

        public internal(set) var baseline: WalletDraft?

        public let editingId: Wallet.ID?

        init(editingId: Wallet.ID?) {
            self.editingId = editingId
        }
    }
}
