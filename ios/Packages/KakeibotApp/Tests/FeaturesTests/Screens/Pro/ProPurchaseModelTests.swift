@testable import FeatureModels
@testable import Features
import Testing

@MainActor
struct ProPurchaseModelTests {
    @Test
    func loadsPrice() async {
        let model = ProPurchaseModel(store: .stub(price: .success("¥600")))

        await model.load()

        #expect(model.input.price == "¥600")
        #expect(model.output.purchaseTitle == "¥600 で購入する")
    }

    @Test
    func keepsPlainTitleWhenPriceFails() async {
        let model = ProPurchaseModel(store: .stub(price: .failure(StubError())))

        await model.load()

        #expect(model.input.price == nil)
        #expect(model.output.purchaseTitle == "購入する")
    }

    @Test
    func showsCachedPriceBeforeLoading() {
        let model = ProPurchaseModel(store: .stub(cachedPrice: "¥600"))

        #expect(model.input.price == "¥600")
        #expect(model.output.purchaseTitle == "¥600 で購入する")
    }

    @Test
    func keepsCachedPriceWhenReloadFails() async {
        let model = ProPurchaseModel(store: .stub(cachedPrice: "¥600"))

        await model.load()

        #expect(model.output.purchaseTitle == "¥600 で購入する")
    }

    @Test
    func keepsPlainTitleBeforeLoading() {
        let model = ProPurchaseModel(store: .stub())
        #expect(model.output.purchaseTitle == "購入する")
    }

    @Test
    func purchaseUnlocks() async {
        let model = ProPurchaseModel(store: .stub(purchase: .success(.unlocked)))

        let isUnlocked = await model.purchase()

        #expect(isUnlocked)
        #expect(model.state.notices.error.message == nil)
        #expect(!model.output.isWorking)
    }

    @Test
    func placesOutcomeWhenPurchaseUnlocks() async {
        let model = ProPurchaseModel(store: .stub(purchase: .success(.unlocked)))

        _ = await model.purchase()
        let first = model.state.outcome
        _ = await model.purchase()

        #expect(first.value == .purchase)
        #expect(model.state.outcome != first)
    }

    @Test
    func placesNoOutcomeWhenPurchaseStaysLocked() async {
        let model = ProPurchaseModel(store: .stub(purchase: .success(.locked)))

        _ = await model.purchase()

        #expect(model.state.outcome.value == nil)
    }

    @Test
    func placesOutcomeOnlyWhenRestoreUnlocks() async {
        let locked = ProPurchaseModel(store: .stub(restore: .success(.locked)))
        let unlocked = ProPurchaseModel(store: .stub(restore: .success(.unlocked)))

        _ = await locked.restore()
        _ = await unlocked.restore()

        #expect(locked.state.outcome.value == nil)
        #expect(unlocked.state.outcome.value == .restore)
    }

    @Test
    func purchaseStaysLockedWhenCancelled() async {
        let model = ProPurchaseModel(store: .stub(purchase: .success(.locked)))

        let isUnlocked = await model.purchase()

        #expect(!isUnlocked)
        #expect(model.state.notices.error.message == nil)
    }

    @Test
    func tellsWhenPurchaseFails() async {
        let model = ProPurchaseModel(store: .stub(purchase: .failure(StubError())))

        let isUnlocked = await model.purchase()

        #expect(!isUnlocked)
        #expect(model.state.notices.error.message == "購入できませんでした。時間をおいて試してください")
        #expect(model.state.notices.error.tone == .error)
        #expect(!model.output.isWorking)
    }

    @Test
    func restoreUnlocks() async {
        let model = ProPurchaseModel(store: .stub(restore: .success(.unlocked)))

        let isUnlocked = await model.restore()

        #expect(isUnlocked)
        #expect(model.state.notices.error.message == nil)
    }

    @Test
    func informsWhenNothingToRestore() async {
        let model = ProPurchaseModel(store: .stub(restore: .success(.locked)))

        let isUnlocked = await model.restore()

        #expect(!isUnlocked)
        #expect(model.state.notices.error.message == "復元できる購入が見つかりませんでした")
        #expect(model.state.notices.error.tone == .info)
    }

    @Test
    func staysQuietWhenRestoreIsCancelled() async {
        let model = ProPurchaseModel(store: .stub(restore: .failure(ProStoreError.cancelled)))

        let isUnlocked = await model.restore()

        #expect(!isUnlocked)
        #expect(model.state.notices.error.message == nil)
    }

    @Test
    func tellsWhenRestoreFails() async {
        let model = ProPurchaseModel(store: .stub(restore: .failure(StubError())))

        let isUnlocked = await model.restore()

        #expect(!isUnlocked)
        #expect(model.state.notices.error.message == "購入を復元できませんでした。時間をおいて試してください")
        #expect(model.state.notices.error.tone == .error)
        #expect(model.state.working == nil)
    }

    @Test
    func clearsPreviousNoticeOnNextTry() async {
        let model = ProPurchaseModel(store: .stub(restore: .success(.unlocked)))
        model.state.notices.error.show("前の失敗")

        let isUnlocked = await model.restore()

        #expect(isUnlocked)
        #expect(model.state.notices.error.message == nil)
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
