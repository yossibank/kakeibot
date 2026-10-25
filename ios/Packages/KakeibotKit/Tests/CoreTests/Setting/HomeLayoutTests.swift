import Core
import Testing

struct HomeLayoutTests {
    @Test
    func addsMissingSectionsAndDropsRepeats() {
        let layout = HomeLayout(order: [.recent, .budget, .recent])

        #expect(layout.order == [.recent, .budget, .customize, .templates, .bills, .stamps])
    }

    @Test
    func hidesAddedSectionsOutsideTheStandard() {
        let layout = HomeLayout(order: [.budget, .templates, .recent])

        #expect(layout.visible == [.budget, .templates, .recent, .customize])
        #expect(layout.hidden == [.bills, .stamps])
    }

    @Test
    func showsListedSectionsOutsideTheStandard() {
        let layout = HomeLayout(order: HomeSection.allCases)

        #expect(layout.visible == HomeSection.allCases)
    }

    @Test
    func keepsOneSectionShown() {
        let layout = HomeLayout(
            order: [.templates, .budget, .recent],
            hidden: Set(HomeSection.allCases)
        )

        #expect(layout.visible == [.templates])
    }

    @Test
    func refusesToHideTheLastShownSection() {
        var layout = HomeLayout(hidden: [.customize, .budget, .templates])

        layout.setHidden(.recent, true)

        #expect(!layout.canHide(.recent))
        #expect(layout.visible == [.recent])

        layout.setHidden(.budget, false)

        #expect(layout.canHide(.recent))
        #expect(layout.visible == [.budget, .recent])
    }

    @Test
    func movesWithinBounds() {
        var layout = HomeLayout.standard

        layout.move(.budget, to: 10)

        #expect(layout.order == [.customize, .templates, .recent, .bills, .stamps, .budget])

        layout.move(.recent, to: -1)

        #expect(layout.order == [.recent, .customize, .templates, .bills, .stamps, .budget])
    }
}
