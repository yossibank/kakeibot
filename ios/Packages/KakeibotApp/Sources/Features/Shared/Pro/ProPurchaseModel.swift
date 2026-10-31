import DesignSystem
import Observation

@MainActor
@Observable
public final class ProPurchaseModel {
    public private(set) var price: String?
    public private(set) var isWorking = false

    public internal(set) var errorNotice = ErrorNotice()

    private let store: ProStore

    public init(store: ProStore) {
        self.store = store
    }
}

public extension ProPurchaseModel {
    var purchaseTitle: String {
        guard let price else {
            return "購入する"
        }

        return "\(price) で購入する"
    }

    func load() async {
        price = try? await store.price()
    }

    func purchase() async -> Bool {
        let status = await work(failedMessage: Self.purchaseFailedMessage) {
            try await store.purchase()
        }

        return status?.isUnlocked == true
    }

    func restore() async -> Bool {
        let status = await work(failedMessage: Self.restoreFailedMessage) {
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

    func work(
        failedMessage: String,
        _ operation: () async throws -> ProStatus
    ) async -> ProStatus? {
        guard !isWorking else {
            return nil
        }

        isWorking = true
        errorNotice.clear()

        defer {
            isWorking = false
        }

        do {
            return try await operation()
        } catch ProStoreError.cancelled {
            return nil
        } catch {
            errorNotice.show(failedMessage)
            return nil
        }
    }
}
