import DesignSystem
import Foundation
import Observation
import OSLog

@MainActor
@Observable
public final class ProPurchaseModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(store: ProStore) {
        let state = State()
        let input = Input(price: store.cachedPrice())

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(store: store)
    }
}

public extension ProPurchaseModel {
    enum Work: Sendable {
        case purchase
        case restore

        public var title: String {
            switch self {
            case .purchase: "確かめています"
            case .restore: "購入を確かめています"
            }
        }
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()

        public internal(set) var working: Work?
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var price: String?

        init(price: String?) {
            self.price = price
        }
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        public var isWorking: Bool {
            state.working != nil
        }

        public var purchaseTitle: String {
            guard let price = input.price else {
                return "購入する"
            }

            return "\(price) で購入する"
        }

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }

    func load() async {
        guard let price = try? await dependencies.store.price() else {
            return
        }

        input.price = price
    }

    func purchase() async -> Bool {
        let status = await work(
            .purchase,
            failedMessage: Self.purchaseFailedMessage
        ) {
            try await dependencies.store.purchase()
        }

        return status?.isUnlocked == true
    }

    func restore() async -> Bool {
        let status = await work(
            .restore,
            failedMessage: Self.restoreFailedMessage
        ) {
            try await dependencies.store.restore()
        }

        guard let status else {
            return false
        }

        if !status.isUnlocked {
            state.errorNotice.inform(Self.nothingToRestoreMessage)
        }

        return status.isUnlocked
    }
}

extension ProPurchaseModel {
    struct Dependencies {
        let store: ProStore
    }
}

private extension ProPurchaseModel {
    static let purchaseFailedMessage = "購入できませんでした。時間をおいて試してください"
    static let restoreFailedMessage = "購入を復元できませんでした。時間をおいて試してください"
    static let nothingToRestoreMessage = "復元できる購入が見つかりませんでした"
    static let logger = Logger(subsystem: "com.yossibank.kakeibot", category: "Pro")

    func work(
        _ work: Work,
        failedMessage: String,
        _ operation: () async throws -> ProStatus
    ) async -> ProStatus? {
        guard !output.isWorking else {
            return nil
        }

        state.working = work
        state.errorNotice.clear()

        defer {
            state.working = nil
        }

        do {
            return try await operation()
        } catch ProStoreError.cancelled {
            return nil
        } catch {
            let code = error as NSError
            let detail = String(describing: error)

            Self.logger.error(
                "\(failedMessage, privacy: .public) \(code.domain, privacy: .public) \(code.code) \(detail)"
            )
            state.errorNotice.show(failedMessage)
            return nil
        }
    }
}
