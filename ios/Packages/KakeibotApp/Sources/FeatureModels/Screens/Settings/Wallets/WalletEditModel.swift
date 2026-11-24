import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class WalletEditModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        editing id: Wallet.ID? = nil,
        kind: Wallet.Kind = .cash
    ) {
        let state = State(kind: kind)
        let input = Input(editingId: id)
        let output = Output(input: input, state: state)

        input.baseline = output.draft

        self.state = state
        self.input = input
        self.output = output
        self.dependencies = parts
    }
}

public extension WalletEditModel {
    static func glyph(for kind: Wallet.Kind) -> Icon.Glyph {
        switch kind {
        case .cash: .cash
        case .bank: .bank
        case .card: .card
        case .emoney: .walletPass
        case .point: .coin
        case .other: .other
        case .investment: .invest
        case .loan: .contract
        }
    }
}

extension WalletEditModel {
    static let defaultColor = "#C9A465"

    static func hasEntries(
        of wallet: Wallet,
        in list: EntryList
    ) -> Bool {
        list.entries.contains { entry in
            entry.walletId == wallet.id || entry.toWalletId == wallet.id
        }
    }
}

extension WalletEditModel: SettingsEditModel {
    public var edited: WalletDraft {
        output.draft
    }

    public var problemMessage: String? {
        output.draft.problems.first?.message
    }
}
