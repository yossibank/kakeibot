import Core
import Observation

public extension WalletEditModel {
    @MainActor
    @Observable
    final class Input {
        public internal(set) var balance = 0
        public internal(set) var totalBalance = 0
        public internal(set) var valuations: [Valuation] = []
        public internal(set) var isHidden = false
        public internal(set) var payment: Recurring?
        public internal(set) var recordedKind: Wallet.Kind?
        public internal(set) var hasValuations = false
        public internal(set) var hasEntries = false

        var baseline: WalletDraft?

        let editingId: Wallet.ID?

        init(editingId: Wallet.ID?) {
            self.editingId = editingId
        }
    }
}
