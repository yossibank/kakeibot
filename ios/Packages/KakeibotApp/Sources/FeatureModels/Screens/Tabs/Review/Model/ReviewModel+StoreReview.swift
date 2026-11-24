import Core
import Store

public extension ReviewModel {
    internal static let storeReviewEntries = 10

    func refreshStoreReviewCard() async {
        let isClosed = await (try? dependencies.database.setting(.storeReviewCardClosed)) ?? true
        let count = await (try? dependencies.database.entryHistory().count) ?? 0
        state.showsStoreReviewCard = !isClosed && count >= Self.storeReviewEntries
    }

    func closeStoreReviewCard() async {
        state.showsStoreReviewCard = false
        try? await dependencies.database.setSetting(.storeReviewCardClosed, to: true)
    }

    func openStoreReview() async {
        await closeStoreReviewCard()
        try? await dependencies.database.setSetting(.storeReviewOpened, to: true)
    }
}
