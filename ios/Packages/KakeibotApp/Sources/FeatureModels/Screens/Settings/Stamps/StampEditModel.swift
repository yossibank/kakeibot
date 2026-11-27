import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class StampEditModel: ScreenPerforming {
    public let state: State
    public let input: Input
    public let flow: EditFlow<Void>

    let dependencies: ScreenParts

    public init(
        parts: ScreenParts,
        editing id: ShelfIcon.ID? = nil
    ) {
        let state = State(wait: parts.wait)
        let input = Input(editingId: id, baseline: state.submodels.icon.draft)

        self.state = state
        self.input = input
        self.flow = EditFlow(source: Source(state: state, input: input, parts: parts))
        self.dependencies = parts
    }
}

public extension StampEditModel {
    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    struct Submodels {
        public let icon = SettingsIconEditorModel(glyph: .star)
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public let notices: Notices
        public let submodels = Submodels()

        init(wait: ScreenWait) {
            self.notices = Notices(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var baseline: IconDraft?
        public internal(set) var isHidden = false

        public let editingId: ShelfIcon.ID?

        init(
            editingId: ShelfIcon.ID?,
            baseline: IconDraft
        ) {
            self.editingId = editingId
            self.baseline = baseline
        }
    }
}

extension StampEditModel {
    @MainActor
    struct Source {
        let state: State
        let input: Input
        let dependencies: ScreenParts

        init(
            state: State,
            input: Input,
            parts: ScreenParts
        ) {
            self.state = state
            self.input = input
            self.dependencies = parts
        }
    }
}

public extension StampEditModel {
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
                state.notices.error.show(Self.loadFailedMessage)
                return
            }

            state.submodels.icon.apply(saved)
            input.isHidden = shelfIcon.archivedAt != nil
            input.baseline = state.submodels.icon.draft
        } catch {
            state.notices.error.show(Self.loadFailedMessage)
        }
    }

    @discardableResult
    func save() async -> Void? {
        await source.store()
    }
}

extension StampEditModel {
    var source: Source {
        Source(state: state, input: input, parts: dependencies)
    }
}

private extension StampEditModel {
    static let loadFailedMessage = "スタンプを読めませんでした"
}

extension StampEditModel.Source: EditFlowSource {
    var isEditing: Bool {
        input.editingId != nil
    }

    var isChanged: Bool {
        input.baseline.map { $0 != state.submodels.icon.draft } ?? false
    }

    var problem: String? {
        state.submodels.icon.draft.problems.first?.message
    }

    var isHidden: Bool {
        input.isHidden
    }

    func store() async -> Void? {
        do {
            try await dependencies.database.save(
                state.submodels.icon.draft,
                editing: input.editingId,
                at: dependencies.clock.now
            )

            return ()
        } catch {
            state.notices.error.show(SettingsEditMessage.saveFailed, for: error)
            return nil
        }
    }

    func storeHidden(_ isHidden: Bool) async throws {
        guard let editingId = input.editingId else {
            return
        }

        try await dependencies.database.setHidden(
            editingId,
            isHidden: isHidden,
            at: dependencies.clock.now
        )

        input.isHidden = isHidden
    }

    func remove() async throws -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        return try await dependencies.database.deleteShelfIcon(editingId)
    }
}
