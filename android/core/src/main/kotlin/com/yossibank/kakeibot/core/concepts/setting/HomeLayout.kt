package com.yossibank.kakeibot.core.concepts.setting

class HomeLayout private constructor(
    val order: List<HomeSection>,
    val hidden: Set<HomeSection>,
) {
    sealed interface Slot {
        val section: HomeSection?

        data class Section(
            override val section: HomeSection,
        ) : Slot

        data object Boundary : Slot {
            override val section: HomeSection?
                get() = null
        }
    }

    val visible: List<HomeSection>
        get() = order.filter { it !in hidden }

    val slots: List<Slot>
        get() {
            val shown = visible.map { Slot.Section(it) }
            val hiddenSlots = order.filter(::isHidden).map { Slot.Section(it) }

            return shown + Slot.Boundary + hiddenSlots
        }

    fun isHidden(section: HomeSection): Boolean = section in hidden

    fun canHide(section: HomeSection): Boolean = isHidden(section) || visible.size > 1

    fun move(
        section: HomeSection,
        toSlot: Int,
    ): HomeLayout {
        val slots = this.slots.toMutableList()
        val from = slots.indexOf(Slot.Section(section))

        if (from < 0) {
            return this
        }

        slots.removeAt(from)

        val lowerClamped = maxOf(toSlot, 0)
        val target = minOf(lowerClamped, slots.size)

        slots.add(target, Slot.Section(section))

        val boundary = slots.indexOf(Slot.Boundary)

        if (boundary <= 0) {
            return this
        }

        val shown = slots.subList(0, boundary).mapNotNull { it.section }
        val hiddenSections = slots.subList(boundary + 1, slots.size).mapNotNull { it.section }

        return HomeLayout(
            order = shown + hiddenSections,
            hidden = hiddenSections.toSet(),
        )
    }

    fun setHidden(
        section: HomeSection,
        isHidden: Boolean,
    ): HomeLayout {
        if (!isHidden) {
            return HomeLayout(
                order = order,
                hidden = hidden - section,
            )
        }

        if (!canHide(section)) {
            return this
        }

        return HomeLayout(
            order = order,
            hidden = hidden + section,
        )
    }

    override fun equals(other: Any?): Boolean = other is HomeLayout && order == other.order && hidden == other.hidden

    override fun hashCode(): Int = 31 * order.hashCode() + hidden.hashCode()

    companion object {
        val standard = HomeLayout()

        operator fun invoke(
            order: List<HomeSection> = HomeSection.standard,
            hidden: Set<HomeSection> = emptySet(),
        ): HomeLayout {
            val listed = order.distinct()
            val missing = HomeSection.entries.filter { it !in listed }
            val fullOrder = listed + missing
            val added = missing.filter { it !in HomeSection.standard }
            val allHidden = hidden + added
            val leading = fullOrder.take(1)

            return HomeLayout(
                order = fullOrder,
                hidden = if (allHidden.size < fullOrder.size) allHidden else allHidden - leading.toSet(),
            )
        }
    }
}
