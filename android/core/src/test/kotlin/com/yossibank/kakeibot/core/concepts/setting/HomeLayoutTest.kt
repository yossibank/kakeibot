package com.yossibank.kakeibot.core.concepts.setting

import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class HomeLayoutTest {
    @Test
    fun addsMissingSectionsAndDropsRepeats() {
        val layout = HomeLayout(
            order = listOf(
                HomeSection.recent,
                HomeSection.budget,
                HomeSection.recent,
            ),
        )

        assertEquals(
            listOf(
                HomeSection.recent,
                HomeSection.budget,
                HomeSection.customize,
                HomeSection.templates,
                HomeSection.bills,
                HomeSection.stamps,
            ),
            layout.order,
        )
    }

    @Test
    fun hidesAddedSectionsOutsideTheStandard() {
        val layout = HomeLayout(
            order = listOf(
                HomeSection.budget,
                HomeSection.templates,
                HomeSection.recent,
            ),
        )

        assertEquals(
            listOf(
                HomeSection.budget,
                HomeSection.templates,
                HomeSection.recent,
                HomeSection.customize,
            ),
            layout.visible,
        )
        assertEquals(
            setOf(
                HomeSection.bills,
                HomeSection.stamps,
            ),
            layout.hidden,
        )
    }

    @Test
    fun showsListedSectionsOutsideTheStandard() {
        val layout = HomeLayout(order = HomeSection.entries)

        assertEquals(HomeSection.entries, layout.visible)
    }

    @Test
    fun keepsOneSectionShown() {
        val layout = HomeLayout(
            order = listOf(
                HomeSection.templates,
                HomeSection.budget,
                HomeSection.recent,
            ),
            hidden = HomeSection.entries.toSet(),
        )

        assertEquals(listOf(HomeSection.templates), layout.visible)
    }

    @Test
    fun refusesToHideTheLastShownSection() {
        var layout = HomeLayout(
            hidden = setOf(
                HomeSection.customize,
                HomeSection.budget,
                HomeSection.templates,
            ),
        )

        layout = layout.setHidden(HomeSection.recent, true)

        assertFalse(layout.canHide(HomeSection.recent))
        assertEquals(listOf(HomeSection.recent), layout.visible)

        layout = layout.setHidden(HomeSection.budget, false)

        assertTrue(layout.canHide(HomeSection.recent))
        assertEquals(
            listOf(
                HomeSection.budget,
                HomeSection.recent,
            ),
            layout.visible,
        )
    }

    @Test
    fun listsHiddenSectionsBelowTheBoundary() {
        val layout = HomeLayout.standard

        assertEquals(
            listOf(
                HomeLayout.Slot.Section(HomeSection.customize),
                HomeLayout.Slot.Section(HomeSection.budget),
                HomeLayout.Slot.Section(HomeSection.templates),
                HomeLayout.Slot.Section(HomeSection.recent),
                HomeLayout.Slot.Boundary,
                HomeLayout.Slot.Section(HomeSection.bills),
                HomeLayout.Slot.Section(HomeSection.stamps),
            ),
            layout.slots,
        )
    }

    @Test
    fun hidesAndShowsAcrossTheBoundary() {
        var layout = HomeLayout.standard

        layout = layout.move(HomeSection.budget, toSlot = 10)

        assertEquals(
            listOf(
                HomeSection.customize,
                HomeSection.templates,
                HomeSection.recent,
            ),
            layout.visible,
        )
        assertEquals(
            setOf(
                HomeSection.budget,
                HomeSection.bills,
                HomeSection.stamps,
            ),
            layout.hidden,
        )

        layout = layout.move(HomeSection.stamps, toSlot = -1)

        assertEquals(
            listOf(
                HomeSection.stamps,
                HomeSection.customize,
                HomeSection.templates,
                HomeSection.recent,
            ),
            layout.visible,
        )
        assertEquals(
            setOf(
                HomeSection.budget,
                HomeSection.bills,
            ),
            layout.hidden,
        )
    }

    @Test
    fun keepsTheLastShownSectionAboveTheBoundary() {
        var layout = HomeLayout(
            hidden = setOf(
                HomeSection.customize,
                HomeSection.budget,
                HomeSection.templates,
            ),
        )

        layout = layout.move(HomeSection.recent, toSlot = 3)

        assertEquals(listOf(HomeSection.recent), layout.visible)
    }
}
