import DesignSystem
import Foundation
import Observation
import OSLog

@MainActor
@Observable
public final class ProPurchaseModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        store: ProStore,
        wait: ScreenWait = .system
    ) {
        let state = State(wait: wait)
        let input = Input(price: store.cachedPrice())

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(store: store)
    }
}

public extension ProPurchaseModel {
    enum Work: Hashable, Sendable {
        case purchase
        case restore
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public let notices: Notices

        public internal(set) var outcome = ScreenOutcome<Work>()

        public let task = ModelTask<Work>()

        init(wait: ScreenWait) {
            self.notices = Notices(wait: wait)
        }
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

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }
}

extension ProPurchaseModel {
    struct Dependencies {
        let store: ProStore
    }
}

public extension ProPurchaseModel {
    func load() async {
        guard let price = try? await dependencies.store.price() else {
            return
        }

        input.price = price
    }

    @discardableResult
    func purchase() async -> Bool {
        let status = await work(
            .purchase,
            failedMessage: Self.purchaseFailedMessage
        ) {
            try await dependencies.store.purchase()
        }

        guard status?.isUnlocked == true else {
            return false
        }

        state.outcome.send(.purchase)

        return true
    }

    @discardableResult
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

        guard status.isUnlocked else {
            state.notices.error.inform(Self.nothingToRestoreMessage)
            return false
        }

        state.outcome.send(.restore)

        return true
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
        guard !state.task.isRunning else {
            return nil
        }

        state.notices.error.clear()

        do {
            return try await state.task.attempt(work) {
                try await operation()
            }
        } catch ProStoreError.cancelled {
            return nil
        } catch {
            let code = error as NSError
            let detail = String(describing: error)

            Self.logger.error(
                "\(failedMessage, privacy: .public) \(code.domain, privacy: .public) \(code.code) \(detail)"
            )

            state.notices.error.show(failedMessage)

            return nil
        }
    }
}

public extension ProPurchaseModel.Output {
    var isWorking: Bool {
        state.task.isRunning
    }

    var purchaseTitle: String {
        guard let price = input.price else {
            return "購入する"
        }

        return "\(price) で購入する"
    }
}

public extension ProPurchaseModel.Work {
    var title: String {
        switch self {
        case .purchase: "確かめています"
        case .restore: "購入を確かめています"
        }
    }
}
