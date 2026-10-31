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
        await work(failedMessage: Self.purchaseFailedMessage) {
            try await store.purchase()
        }
    }

    func restore() async -> Bool {
        let isUnlocked = await work(failedMessage: Self.restoreFailedMessage) {
            try await store.restore()
        }

        if !isUnlocked,
           errorNotice.message == nil {
            errorNotice.inform(Self.nothingToRestoreMessage)
        }

        return isUnlocked
    }
}

private extension ProPurchaseModel {
    static let purchaseFailedMessage = "購入できませんでした。時間をおいて試してください"
    static let restoreFailedMessage = "購入を復元できませんでした。時間をおいて試してください"
    static let nothingToRestoreMessage = "復元できる購入が見つかりませんでした"

    func work(
        failedMessage: String,
        _ operation: () async throws -> ProStatus
    ) async -> Bool {
        guard !isWorking else {
            return false
        }

        isWorking = true
        errorNotice.clear()

        defer {
            isWorking = false
        }

        do {
            return try await operation().isUnlocked
        } catch {
            errorNotice.show(failedMessage)
            return false
        }
    }
}
