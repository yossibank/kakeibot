@testable import Features
import Testing

@MainActor
struct ProPurchaseModelTests {
    @Test
    func loadsPrice() async {
        let model = ProPurchaseModel(store: .stub(price: .success("¥600")))

        await model.load()

        #expect(model.price == "¥600")
        #expect(model.purchaseTitle == "¥600 で購入する")
    }

    @Test
    func keepsPlainTitleWhenPriceFails() async {
        let model = ProPurchaseModel(store: .stub(price: .failure(StubError())))

        await model.load()

        #expect(model.price == nil)
        #expect(model.purchaseTitle == "購入する")
    }

    @Test
    func showsCachedPriceBeforeLoading() {
        let model = ProPurchaseModel(store: .stub(cachedPrice: "¥600"))

        #expect(model.price == "¥600")
        #expect(model.purchaseTitle == "¥600 で購入する")
    }

    @Test
    func keepsCachedPriceWhenReloadFails() async {
        let model = ProPurchaseModel(store: .stub(cachedPrice: "¥600"))

        await model.load()

        #expect(model.purchaseTitle == "¥600 で購入する")
    }

    @Test
    func keepsPlainTitleBeforeLoading() {
        let model = ProPurchaseModel(store: .stub())
        #expect(model.purchaseTitle == "購入する")
    }

    @Test
    func purchaseUnlocks() async {
        let model = ProPurchaseModel(store: .stub(purchase: .success(.unlocked)))

        let isUnlocked = await model.purchase()

        #expect(isUnlocked)
        #expect(model.errorNotice.message == nil)
        #expect(!model.isWorking)
    }

    @Test
    func purchaseStaysLockedWhenCancelled() async {
        let model = ProPurchaseModel(store: .stub(purchase: .success(.locked)))

        let isUnlocked = await model.purchase()

        #expect(!isUnlocked)
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func tellsWhenPurchaseFails() async {
        let model = ProPurchaseModel(store: .stub(purchase: .failure(StubError())))

        let isUnlocked = await model.purchase()

        #expect(!isUnlocked)
        #expect(model.errorNotice.message == "購入できませんでした。時間をおいて試してください")
        #expect(model.errorNotice.tone == .error)
        #expect(!model.isWorking)
    }

    @Test
    func restoreUnlocks() async {
        let model = ProPurchaseModel(store: .stub(restore: .success(.unlocked)))

        let isUnlocked = await model.restore()

        #expect(isUnlocked)
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func informsWhenNothingToRestore() async {
        let model = ProPurchaseModel(store: .stub(restore: .success(.locked)))

        let isUnlocked = await model.restore()

        #expect(!isUnlocked)
        #expect(model.errorNotice.message == "復元できる購入が見つかりませんでした")
        #expect(model.errorNotice.tone == .info)
    }

    @Test
    func staysQuietWhenRestoreIsCancelled() async {
        let model = ProPurchaseModel(store: .stub(restore: .failure(ProStoreError.cancelled)))

        let isUnlocked = await model.restore()

        #expect(!isUnlocked)
        #expect(model.errorNotice.message == nil)
    }

    @Test
    func tellsWhenRestoreFails() async {
        let model = ProPurchaseModel(store: .stub(restore: .failure(StubError())))

        let isUnlocked = await model.restore()

        #expect(!isUnlocked)
        #expect(model.errorNotice.message == "購入を復元できませんでした。時間をおいて試してください")
        #expect(model.errorNotice.tone == .error)
        #expect(model.working == nil)
    }

    @Test
    func clearsPreviousNoticeOnNextTry() async {
        let model = ProPurchaseModel(store: .stub(restore: .success(.unlocked)))
        model.errorNotice.show("前の失敗")

        let isUnlocked = await model.restore()

        #expect(isUnlocked)
        #expect(model.errorNotice.message == nil)
    }
}

extension ProPurchaseModelTests {
    struct StubError: Error {}
}

private extension ProStore {
    static func stub(
        price: Result<String, any Error> = .failure(ProPurchaseModelTests.StubError()),
        cachedPrice: String? = nil,
        purchase: Result<ProStatus, any Error> = .success(.locked),
        restore: Result<ProStatus, any Error> = .success(.locked)
    ) -> Self {
        Self(
            status: {
                .locked
            },
            updates: {
                AsyncStream { continuation in
                    continuation.finish()
                }
            },
            price: {
                try price.get()
            },
            cachedPrice: {
                cachedPrice
            },
            purchase: {
                try purchase.get()
            },
            restore: {
                try restore.get()
            }
        )
    }
}
