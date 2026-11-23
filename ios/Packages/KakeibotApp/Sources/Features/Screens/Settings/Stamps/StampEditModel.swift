import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class StampEditModel {
    public internal(set) var isHidden = false

    public internal(set) var errorNotice = ErrorNotice()

    public let icon = SettingsIconEditorModel(glyph: .star)

    private(set) var baseline: IconDraft?

    let editingId: ShelfIcon.ID?

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        editing id: ShelfIcon.ID? = nil
    ) {
        self.database = database
        self.editingId = id
        self.baseline = icon.draft
    }
}

public extension StampEditModel {
    func load() async {
        guard let editingId else {
            return
        }

        do {
            let shelf = try await database.shelfIconList()
            let shelfIcon = shelf.shelfIcons.first { $0.id == editingId }

            guard
                let shelfIcon,
                let saved = shelf.icons[shelfIcon.iconId]
            else {
                errorNotice.show(Self.loadFailedMessage)
                return
            }

            icon.apply(saved)

            isHidden = shelfIcon.archivedAt != nil
            baseline = icon.draft
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func save() async -> Bool {
        do {
            try await database.save(
                icon.draft,
                editing: editingId,
                at: Date()
            )

            return true
        } catch {
            errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }
}

private extension StampEditModel {
    static let loadFailedMessage = "スタンプを読めませんでした"
}

extension StampEditModel: SettingsEditRemoving {
    var edited: IconDraft {
        icon.draft
    }

    var problemMessage: String? {
        icon.draft.problems.first?.message
    }

    func remove(_ id: ShelfIcon.ID) async throws -> Deletion {
        try await database.deleteShelfIcon(id)
    }

    func saveHidden(
        _ id: ShelfIcon.ID,
        isHidden: Bool
    ) async throws {
        try await database.setHidden(
            id,
            isHidden: isHidden,
            at: Date()
        )
    }
}
