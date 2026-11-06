package com.yossibank.kakeibot.store.writes

import com.yossibank.kakeibot.core.concepts.icon.IconDraft
import com.yossibank.kakeibot.core.concepts.icon.ShelfIcon
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.database.insertShelfIfEmpty
import com.yossibank.kakeibot.store.queries.methods.entryList
import com.yossibank.kakeibot.store.queries.methods.iconShelf
import com.yossibank.kakeibot.store.writes.methods.ShelfIconWriteError
import com.yossibank.kakeibot.store.writes.methods.ShelfIconWriteException
import com.yossibank.kakeibot.store.writes.methods.deleteShelfIcon
import com.yossibank.kakeibot.store.writes.methods.reorderShelfIcons
import com.yossibank.kakeibot.store.writes.methods.saveShelfIcon
import com.yossibank.kakeibot.store.writes.methods.setShelfIconHidden
import kotlinx.coroutines.test.runTest
import org.junit.Test
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class ShelfIconWriteTest {
    @Test
    fun addsShelfIconAtTheEnd() = runTest {
        val setup = Setup.make()

        val saved = setup.database.saveShelfIcon(setup.draft, at = setup.now)
        val shelf = setup.database.iconShelf()
        val icon = assertNotNull(shelf.icons[saved.iconId])

        assertEquals(8, saved.sortOrder)
        assertEquals(saved, shelf.shelfIcons.last())
        assertEquals("🎉", icon.emoji)
        assertEquals("#E07A5F", icon.color)

        setup.database.close()
    }

    @Test
    fun updatesIconInPlace() = runTest {
        val setup = Setup.make()
        val later = setup.now.plusSeconds(60)
        val first = setup.firstShelfIcon()

        val draft = IconDraft(
            mark = IconDraft.Mark.Text("推し"),
            color = "#9C6ADE",
        )

        val updated = setup.database.saveShelfIcon(
            draft,
            editing = first.id,
            at = later,
        )

        val shelf = setup.database.iconShelf()
        val icon = assertNotNull(shelf.icons[updated.iconId])

        assertEquals(first.id, updated.id)
        assertEquals(first.iconId, updated.iconId)
        assertEquals(first.sortOrder, updated.sortOrder)
        assertEquals(later, updated.updatedAt)
        assertEquals("推し", icon.text)
        assertNull(icon.glyph)

        setup.database.close()
    }

    @Test
    fun reordersShelfIcons() = runTest {
        val setup = Setup.make()
        val shelf = setup.database.iconShelf()
        val reversed = shelf.shelfIcons.map { it.id }.reversed()

        setup.database.reorderShelfIcons(reversed, at = setup.now)
        val reordered = setup.database.iconShelf()

        assertEquals(reversed, reordered.shelfIcons.map { it.id })

        setup.database.close()
    }

    @Test
    fun hidesAndShowsShelfIcon() = runTest {
        val setup = Setup.make()
        val first = setup.firstShelfIcon()

        setup.database.setShelfIconHidden(
            first.id,
            isHidden = true,
            at = setup.now,
        )

        val hidden = setup.database.iconShelf()
        val list = setup.database.entryList()

        setup.database.setShelfIconHidden(
            first.id,
            isHidden = false,
            at = setup.now,
        )

        val shown = setup.database.iconShelf()

        assertEquals(setup.now, hidden.shelfIcons.firstOrNull()?.archivedAt)
        assertEquals(8, hidden.shelfIcons.size)
        assertNotNull(list.icons[first.iconId])
        assertNull(shown.shelfIcons.firstOrNull()?.archivedAt)

        setup.database.close()
    }

    @Test
    fun deletesShelfIcon() = runTest {
        val setup = Setup.make()
        val first = setup.firstShelfIcon()

        setup.database.deleteShelfIcon(first.id)
        val shelf = setup.database.iconShelf()

        assertEquals(7, shelf.shelfIcons.size)
        assertFalse(shelf.shelfIcons.any { it.id == first.id })

        setup.database.close()
    }

    @Test
    fun rejectsUnknownShelfIcon() = runTest {
        val setup = Setup.make()

        val saving = assertFailsWith<ShelfIconWriteException> {
            setup.database.saveShelfIcon(
                setup.draft,
                editing = Identifier(),
                at = setup.now,
            )
        }

        val hiding = assertFailsWith<ShelfIconWriteException> {
            setup.database.setShelfIconHidden(
                Identifier(),
                isHidden = true,
                at = setup.now,
            )
        }

        assertEquals(ShelfIconWriteError.shelfIconNotFound, saving.error)
        assertEquals(ShelfIconWriteError.shelfIconNotFound, hiding.error)

        setup.database.close()
    }

    @Test
    fun rejectsInvalidDraft() = runTest {
        val setup = Setup.make()

        val draft = IconDraft(
            mark = IconDraft.Mark.Text(""),
            color = "#E07A5F",
        )

        assertFailsWith<Exception> {
            setup.database.saveShelfIcon(draft, at = setup.now)
        }

        val shelf = setup.database.iconShelf()

        assertEquals(8, shelf.shelfIcons.size)

        setup.database.close()
    }

    class Setup(
        val database: AppDatabase,
        val now: Instant,
        val draft: IconDraft,
    ) {
        suspend fun firstShelfIcon(): ShelfIcon {
            val shelf = database.iconShelf()

            return assertNotNull(shelf.shelfIcons.firstOrNull())
        }

        companion object {
            suspend fun make(): Setup {
                val database = AppDatabase.inMemory()
                val now = Instant.ofEpochSecond(1_791_000_000)

                val draft = IconDraft(
                    mark = IconDraft.Mark.Emoji("🎉"),
                    color = "#E07A5F",
                )

                database.insertShelfIfEmpty(now)

                return Setup(
                    database = database,
                    now = now,
                    draft = draft,
                )
            }
        }
    }
}
