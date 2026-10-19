import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class ShelfIconEditModel {
    public internal(set) var errorNotice = ErrorNotice()

    public let icon = IconEditModel(glyph: .star)

    private var baseline: IconDraft?

    private let database: AppDatabase
    private let editingId: ShelfIcon.ID?

    public init(
        database: AppDatabase,
        editing id: ShelfIcon.ID? = nil
    ) {
        self.database = database
        self.editingId = id
        self.baseline = icon.draft
    }
}

public extension ShelfIconEditModel {
    var isEditing: Bool {
        editingId != nil
    }

    var isChanged: Bool {
        baseline.map { $0 != icon.draft } ?? false
    }

    var canSave: Bool {
        icon.draft.problems.isEmpty
    }

    var saveTitle: String {
        SettingsSaveTitle.text(
            problem: icon.draft.problems.first?.message,
            isEditing: isEditing
        )
    }

    func load() async {
        guard let editingId else {
            return
        }

        do {
            let shelf = try await database.iconShelf()
            let shelfIcon = shelf.shelfIcons.first { $0.id == editingId }

            guard
                let shelfIcon,
                let saved = shelf.icons[shelfIcon.iconId]
            else {
                errorNotice.show(IconEditModel.shelfLoadFailedMessage)
                return
            }

            icon.apply(saved)
            baseline = icon.draft
        } catch {
            errorNotice.show(IconEditModel.shelfLoadFailedMessage)
        }
    }

    func save() async -> Bool {
        do {
            try await database.saveShelfIcon(
                icon.draft,
                editing: editingId,
                at: Date()
            )

            return true
        } catch {
            errorNotice.show(Self.saveFailedMessage)
            return false
        }
    }

    func remove() async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await database.removeShelfIcon(editingId, at: Date())
            return true
        } catch {
            errorNotice.show(Self.removeFailedMessage)
            return false
        }
    }
}

private extension ShelfIconEditModel {
    static let saveFailedMessage = "保存できませんでした"
    static let removeFailedMessage = "棚から消せませんでした"
}
