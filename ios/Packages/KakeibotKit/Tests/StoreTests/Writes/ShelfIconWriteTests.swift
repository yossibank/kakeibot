import Core
import Foundation
import Store
import Testing

struct ShelfIconWriteTests {
    @Test
    func addsShelfIconAtTheEnd() async throws {
        let setup = try await Setup()

        let saved = try await setup.database.saveShelfIcon(
            setup.draft,
            at: setup.now
        )
        let shelf = try await setup.database.iconShelf()
        let icon = try #require(shelf.icons[saved.iconId])

        #expect(saved.sortOrder == 8)
        #expect(shelf.shelfIcons.last == saved)
        #expect(icon.emoji == "🎉")
        #expect(icon.color == "#E07A5F")
    }

    @Test
    func updatesIconInPlace() async throws {
        let setup = try await Setup()
        let later = setup.now.addingTimeInterval(60)
        let first = try await setup.firstShelfIcon()
        let draft = IconDraft(mark: .text("推し"), color: "#9C6ADE")

        let updated = try await setup.database.saveShelfIcon(
            draft,
            editing: first.id,
            at: later
        )
        let shelf = try await setup.database.iconShelf()
        let icon = try #require(shelf.icons[updated.iconId])

        #expect(updated.id == first.id)
        #expect(updated.iconId == first.iconId)
        #expect(updated.sortOrder == first.sortOrder)
        #expect(updated.updatedAt == later)
        #expect(icon.text == "推し")
        #expect(icon.glyph == nil)
    }

    @Test
    func reordersShelfIcons() async throws {
        let setup = try await Setup()
        let shelf = try await setup.database.iconShelf()
        let ids = shelf.shelfIcons.map(\.id)
        let reversed = Array(ids.reversed())

        try await setup.database.reorderShelfIcons(reversed, at: setup.now)
        let reordered = try await setup.database.iconShelf()

        #expect(reordered.shelfIcons.map(\.id) == reversed)
    }

    @Test
    func hidesAndShowsShelfIcon() async throws {
        let setup = try await Setup()
        let first = try await setup.firstShelfIcon()

        try await setup.database.setShelfIconHidden(
            first.id,
            isHidden: true,
            at: setup.now
        )
        let hidden = try await setup.database.iconShelf()
        let list = try await setup.database.entryList()

        try await setup.database.setShelfIconHidden(
            first.id,
            isHidden: false,
            at: setup.now
        )
        let shown = try await setup.database.iconShelf()

        #expect(hidden.shelfIcons.first?.archivedAt == setup.now)
        #expect(hidden.shelfIcons.count == 8)
        #expect(list.icons[first.iconId] != nil)
        #expect(shown.shelfIcons.first?.archivedAt == nil)
    }

    @Test
    func deletesShelfIcon() async throws {
        let setup = try await Setup()
        let first = try await setup.firstShelfIcon()

        try await setup.database.deleteShelfIcon(first.id)
        let shelf = try await setup.database.iconShelf()

        #expect(shelf.shelfIcons.count == 7)
        #expect(!shelf.shelfIcons.contains { $0.id == first.id })
    }

    @Test
    func rejectsUnknownShelfIcon() async throws {
        let setup = try await Setup()
        let error = AppDatabase.ShelfIconWriteError.shelfIconNotFound

        await #expect(throws: error) {
            try await setup.database.saveShelfIcon(
                setup.draft,
                editing: ShelfIcon.ID(),
                at: setup.now
            )
        }

        await #expect(throws: error) {
            try await setup.database.setShelfIconHidden(
                ShelfIcon.ID(),
                isHidden: true,
                at: setup.now
            )
        }
    }

    @Test
    func rejectsInvalidDraft() async throws {
        let setup = try await Setup()
        let draft = IconDraft(mark: .text(""), color: "#E07A5F")

        await #expect(throws: (any Error).self) {
            try await setup.database.saveShelfIcon(draft, at: setup.now)
        }

        let shelf = try await setup.database.iconShelf()

        #expect(shelf.shelfIcons.count == 8)
    }
}

extension ShelfIconWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
        let draft: IconDraft
    }
}

extension ShelfIconWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertShelfIfEmpty(at: now)
        let draft = IconDraft(mark: .emoji("🎉"), color: "#E07A5F")
        self.init(database: database, now: now, draft: draft)
    }

    func firstShelfIcon() async throws -> ShelfIcon {
        let shelf = try await database.iconShelf()
        return try #require(shelf.shelfIcons.first)
    }
}
