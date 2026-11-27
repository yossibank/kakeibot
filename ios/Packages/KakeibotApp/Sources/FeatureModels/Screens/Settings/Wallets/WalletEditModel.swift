import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class WalletEditModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output
    public let flow: EditFlow<Wallet>

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        editing id: Wallet.ID? = nil,
        kind: Wallet.Kind = .cash
    ) {
        let state = State(kind: kind, wait: parts.wait)
        let input = Input(editingId: id)
        let output = Output(input: input, state: state)
        let source = Source(state: state, input: input, output: output, parts: parts)

        self.state = state
        self.input = input
        self.output = output
        self.flow = EditFlow(source: source)
        self.dependencies = parts

        input.baseline = output.draft
    }
}

extension WalletEditModel {
    @MainActor
    struct Source {
        let state: State
        let input: Input
        let output: Output
        let dependencies: ScreenParts

        init(
            state: State,
            input: Input,
            output: Output,
            parts: ScreenParts
        ) {
            self.state = state
            self.input = input
            self.output = output
            self.dependencies = parts
        }
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

    var source: Source {
        Source(state: state, input: input, output: output, parts: dependencies)
    }

    static func hasEntries(
        of wallet: Wallet,
        in list: EntryList
    ) -> Bool {
        list.entries.contains { entry in
            entry.walletId == wallet.id || entry.toWalletId == wallet.id
        }
    }
}

extension WalletEditModel.Source: EditFlowSource {
    var isEditing: Bool {
        input.editingId != nil
    }

    var isChanged: Bool {
        input.baseline.map { $0 != output.draft } ?? false
    }

    var problem: String? {
        output.draft.problems.first?.message
    }

    var isHidden: Bool {
        input.isHidden
    }

    var asksBeforeHiding: Bool {
        input.totalBalance != 0
    }

    func store() async -> Wallet? {
        do {
            let wallet = try await dependencies.database.save(
                output.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )

            guard
                !output.isEditing,
                output.asksPayment
            else {
                return wallet
            }

            state.addedWallet = wallet
            state.presented.paymentStep.show(.asking)

            return wallet
        } catch {
            state.notices.error.show(SettingsEditMessage.saveFailed, for: error)
            return nil
        }
    }

    func keepsOpen(after saved: Wallet) -> Bool {
        state.addedWallet?.id == saved.id
    }

    func storeHidden(_ isHidden: Bool) async throws {
        guard let editingId = input.editingId else {
            return
        }

        try await dependencies.database.setHidden(
            editingId,
            isHidden: isHidden,
            at: dependencies.clock.now
        )

        input.isHidden = isHidden
    }

    func remove() async throws -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        return try await dependencies.database.deleteWallet(
            editingId,
            at: dependencies.clock.now
        )
    }

    func hideFailedMessage(for error: any Error) -> String {
        switch error as? AppDatabase.WalletWriteError {
        case .lastShownWallet: AppDatabase.WalletWriteError.lastShownMessage
        default: SettingsEditMessage.saveFailed
        }
    }

    func deleteFailedMessage(for error: any Error) -> String {
        switch error as? AppDatabase.WalletWriteError {
        case .hasEntries: AppDatabase.WalletWriteError.hasEntriesMessage
        case .lastShownWallet: AppDatabase.WalletWriteError.lastShownDeleteMessage
        default: SettingsEditMessage.deleteFailed
        }
    }
}
