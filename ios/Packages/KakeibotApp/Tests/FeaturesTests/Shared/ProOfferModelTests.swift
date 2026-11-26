import FeatureModels
import Testing

@MainActor
struct ProOfferModelTests {
    @Test
    func showsProAndClosesIt() {
        let model = ProOfferModel()

        model.showPro()
        let shown = model.state.presented.isShowing(.pro)
        model.closePro()

        #expect(shown)
        #expect(!model.state.presented.isShowing(.pro))
    }
}
