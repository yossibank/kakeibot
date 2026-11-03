import Features
import Foundation
import StoreKit
import Synchronization

extension ProStore {
    static let live = Self {
        await ProEntitlement.status()
    } updates: {
        ProEntitlement.updates()
    } price: {
        let price = try await ProEntitlement.product().displayPrice

        ProEntitlement.cachedPrice.withLock { cachedPrice in
            cachedPrice = price
        }

        return price
    } cachedPrice: {
        ProEntitlement.cachedPrice.withLock { $0 }
    } purchase: {
        try await ProEntitlement.purchase()
    } restore: {
        do {
            try await AppStore.sync()
        } catch StoreKitError.userCancelled {
            throw ProStoreError.cancelled
        }

        return await ProEntitlement.refresh()
    }
}

private enum ProEntitlement {
    static let productID = "com.yossibank.kakeibot.pro"
    static let cachedPrice = Mutex<String?>(nil)
    static let listeners = Mutex<[UUID: AsyncStream<ProStatus>.Continuation]>([:])

    static func status() async -> ProStatus {
        for await result in Transaction.currentEntitlements {
            if case let .verified(transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                return .unlocked
            }
        }

        guard case let .verified(latest)? = await Transaction.latest(for: productID) else {
            return .locked
        }

        return latest.revocationDate == nil ? .locked : .revoked
    }

    static func product() async throws -> Product {
        let products = try await Product.products(for: [productID])

        guard let product = products.first else {
            throw ProStoreError.unavailable
        }

        return product
    }

    static func purchase() async throws -> ProStatus {
        let product = try await product()

        switch try await product.purchase() {
        case let .success(.verified(transaction)):
            await transaction.finish()
            return await refresh()

        case .success(.unverified):
            throw ProStoreError.unavailable

        case .pending, .userCancelled:
            return .locked

        @unknown default:
            return .locked
        }
    }

    static func refresh() async -> ProStatus {
        let status = await status()

        listeners.withLock { listeners in
            for continuation in listeners.values {
                continuation.yield(status)
            }
        }

        return status
    }

    static func updates() -> AsyncStream<ProStatus> {
        AsyncStream { continuation in
            let id = UUID()

            listeners.withLock { listeners in
                listeners[id] = continuation
            }

            let transactions = Task {
                for await result in Transaction.updates {
                    if case let .verified(transaction) = result {
                        await transaction.finish()
                    }

                    _ = await refresh()
                }
            }

            continuation.onTermination = { _ in
                transactions.cancel()

                listeners.withLock { listeners in
                    listeners[id] = nil
                }
            }
        }
    }
}
