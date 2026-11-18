import Core
import Store

extension ReviewModel {
    static let storeReviewEntries = 10

    func refreshStoreReviewCard() async {
        let isClosed = await (try? database.setting(.storeReviewCardClosed)) ?? true
        let count = await (try? database.entryHistory().count) ?? 0
        showsStoreReviewCard = !isClosed && count >= Self.storeReviewEntries
    }

    func closeStoreReviewCard() async {
        showsStoreReviewCard = false
        try? await database.setSetting(.storeReviewCardClosed, to: true)
    }

    func openStoreReview() async {
        await closeStoreReviewCard()
        try? await database.setSetting(.storeReviewOpened, to: true)
    }
}
