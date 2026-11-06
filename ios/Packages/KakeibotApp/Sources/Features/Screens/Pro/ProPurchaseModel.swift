import DesignSystem
import Foundation
import Observation
import OSLog

@MainActor
@Observable
public final class ProPurchaseModel {
    public private(set) var price: String?
    public private(set) var working: Work?

    public internal(set) var errorNotice = ErrorNotice()

    private let store: ProStore

    public init(store: ProStore) {
        self.store = store
        self.price = store.cachedPrice()
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

    var isWorking: Bool {
        working != nil
    }

    var purchaseTitle: String {
        guard let price else {
            return "購入する"
        }

        return "\(price) で購入する"
    }

    func load() async {
        guard let price = try? await store.price() else {
            return
        }

        self.price = price
    }

    func purchase() async -> Bool {
        let status = await work(
            .purchase,
            failedMessage: Self.purchaseFailedMessage
        ) {
            try await store.purchase()
        }

        return status?.isUnlocked == true
    }

    func restore() async -> Bool {
        let status = await work(
            .restore,
            failedMessage: Self.restoreFailedMessage
        ) {
            try await store.restore()
        }

        guard let status else {
            return false
        }

        if !status.isUnlocked {
            errorNotice.inform(Self.nothingToRestoreMessage)
        }

        return status.isUnlocked
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
        guard !isWorking else {
            return nil
        }

        working = work
        errorNotice.clear()

        defer {
            working = nil
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
            errorNotice.show(failedMessage)
            return nil
        }
    }
}
