import FeatureModels
import Testing

@MainActor
struct WidgetGuideModelTests {
    @Test
    func startsFromQuickRecordOnHome() {
        let model = WidgetGuideModel()

        #expect(model.state.place == .home)
        #expect(model.state.sample == WidgetGuideSample(widget: .quickRecord, size: .medium))
        #expect(model.state.shownSample == nil)
    }

    @Test
    func choosesSampleShownInCarousel() {
        let model = WidgetGuideModel()
        let budget = WidgetGuideSample(widget: .budget, size: .small)

        model.state.showChosenSample()
        let aligned = model.state.shownSample

        model.state.show(budget)

        #expect(aligned == WidgetGuideSample(widget: .quickRecord, size: .medium))
        #expect(model.state.shownSample == budget)
        #expect(model.state.sample == budget)
    }

    @Test
    func keepsChosenSampleWhileCarouselIsAway() {
        let budget = WidgetGuideSample(widget: .budget, size: .medium)
        let model = WidgetGuideModel(place: .lockScreen, sample: budget)

        model.state.show(nil)
        model.state.place = .home
        model.state.showChosenSample()

        #expect(model.state.sample == budget)
        #expect(model.state.shownSample == budget)
    }
}
