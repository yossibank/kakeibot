import Core
import Store

public extension ReviewModel {
    internal static let storeReviewEntries = 10

    func refreshStoreReviewCard() async {
        let isClosed = await (try? dependencies.database.setting(.storeReviewCardClosed)) ?? true
        let count = await (try? dependencies.database.entryHistory().count) ?? 0

        input.isStoreReviewClosed = isClosed
        input.historyCount = count
    }

    func closeStoreReviewCard() async {
        input.isStoreReviewClosed = true
        try? await dependencies.database.setSetting(.storeReviewCardClosed, to: true)
    }

    func openStoreReview() async {
        await closeStoreReviewCard()
        try? await dependencies.database.setSetting(.storeReviewOpened, to: true)
    }
}

public extension ReviewModel.Output {
    var showsStoreReviewCard: Bool {
        !input.isStoreReviewClosed && input.historyCount >= ReviewModel.storeReviewEntries
    }
}
