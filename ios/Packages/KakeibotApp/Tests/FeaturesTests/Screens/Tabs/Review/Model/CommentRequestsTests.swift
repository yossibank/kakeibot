import FeatureModels
import Testing

struct CommentRequestsTests {
    @Test
    func beginsEachKeyOnceUntilCancelled() {
        var requests = ReviewModel.CommentRequests()

        let first = requests.begin("2026-10")
        let again = requests.begin("2026-10")
        let other = requests.begin("2026-11")
        requests.cancel("2026-10")
        let afterCancel = requests.begin("2026-10")

        #expect(first)
        #expect(!again)
        #expect(other)
        #expect(afterCancel)
    }
}
