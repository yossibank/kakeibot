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
    func listsHiddenSectionsBelowTheBoundary() {
        let layout = HomeLayout.standard

        #expect(
            layout.slots == [
                .section(.budget),
                .section(.customize),
                .section(.templates),
                .section(.recent),
                .boundary,
                .section(.bills),
                .section(.stamps)
            ]
        )
    }

    @Test
    func hidesAndShowsAcrossTheBoundary() {
        var layout = HomeLayout.standard

        layout.move(.budget, toSlot: 10)

        #expect(layout.visible == [.customize, .templates, .recent])
        #expect(layout.hidden == [.budget, .bills, .stamps])

        layout.move(.stamps, toSlot: -1)

        #expect(layout.visible == [.stamps, .customize, .templates, .recent])
        #expect(layout.hidden == [.budget, .bills])
    }

    @Test
    func keepsTheLastShownSectionAboveTheBoundary() {
        var layout = HomeLayout(hidden: [.customize, .budget, .templates])

        layout.move(.recent, toSlot: 3)

        #expect(layout.visible == [.recent])
    }
}
