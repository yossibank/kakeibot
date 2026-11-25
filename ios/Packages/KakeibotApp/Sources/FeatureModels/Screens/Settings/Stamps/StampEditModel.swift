import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class StampEditModel {
    public let state: State
    public let input: Input

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        editing id: ShelfIcon.ID? = nil
    ) {
        let state = State()

        self.state = state
        self.input = Input(editingId: id, baseline: state.icon.draft)
        self.dependencies = parts
    }
}

public extension StampEditModel {
    @MainActor
    @Observable
    final class State: SettingsEditState {
        public var errorNotice = ErrorNotice()
        public var prompt = SettingsEditPrompt()

        public let icon = SettingsIconEditorModel(glyph: .star)
    }

    @MainActor
    @Observable
    final class Input: SettingsEditHidingInput {
        public internal(set) var isHidden = false

        public internal(set) var baseline: IconDraft?

        public let editingId: ShelfIcon.ID?

        init(
            editingId: ShelfIcon.ID?,
            baseline: IconDraft
        ) {
            self.editingId = editingId
            self.baseline = baseline
        }
    }

    func load() async {
        guard let editingId = input.editingId else {
            return
        }

        do {
            let shelf = try await dependencies.database.shelfIconList()
            let shelfIcon = shelf.shelfIcons.first { $0.id == editingId }

            guard
                let shelfIcon,
                let saved = shelf.icons[shelfIcon.iconId]
            else {
                state.errorNotice.show(Self.loadFailedMessage)
                return
            }

            state.icon.apply(saved)

            input.isHidden = shelfIcon.archivedAt != nil
            input.baseline = state.icon.draft
        } catch {
            state.errorNotice.show(Self.loadFailedMessage)
        }
    }

    func save() async -> Bool {
        do {
            try await dependencies.database.save(
                state.icon.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )

            return true
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }
}

private extension StampEditModel {
    static let loadFailedMessage = "スタンプを読めませんでした"
}

extension StampEditModel: SettingsEditRemoving {
    public var edited: IconDraft {
        state.icon.draft
    }

    public var problemMessage: String? {
        state.icon.draft.problems.first?.message
    }

    public func remove(_ id: ShelfIcon.ID) async throws -> Deletion {
        try await dependencies.database.deleteShelfIcon(id)
    }

    public func saveHidden(
        _ id: ShelfIcon.ID,
        isHidden: Bool
    ) async throws {
        try await dependencies.database.setHidden(
            id,
            isHidden: isHidden,
            at: dependencies.clock.now
        )

        input.isHidden = isHidden
    }
}
