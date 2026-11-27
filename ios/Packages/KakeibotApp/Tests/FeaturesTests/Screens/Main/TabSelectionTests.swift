import FeatureModels
import Testing

struct TabSelectionTests {
    @Test
    func startsOnHome() {
        let tabs = MainModel.TabSelection()

        #expect(tabs.current == .home)
        #expect(tabs.visited == [.home])
    }

    @Test
    func remembersVisitedTabs() {
        var tabs = MainModel.TabSelection()

        tabs.select(.review)
        tabs.select(.home)

        #expect(tabs.current == .home)
        #expect(tabs.visited == [.home, .review])
    }
}
