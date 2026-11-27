import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class HomeSectionListModel {
    public let state: State
    public let input = Input()

    let dependencies: Dependencies

    public init(parts: ScreenParts) {
        self.state = State(wait: parts.wait)
        self.dependencies = Dependencies(database: parts.database)
    }
}

public extension HomeSectionListModel {
    struct Dragging: Equatable, Sendable {
        public let section: HomeSection
        public let start: Int
    }

    @MainActor
    struct Notices: ScreenNotices {
        public let error: ErrorNotice

        init(wait: ScreenWait) {
            self.error = ErrorNotice(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class State: NoticesHolding {
        public let notices: Notices

        public internal(set) var layout = HomeLayout.standard
        public internal(set) var dragging: Dragging?

        init(wait: ScreenWait) {
            self.notices = Notices(wait: wait)
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var saved: Loadable<HomeLayout> = .loading

        public let hint = SettingsFoldInput.hint(.homeSections)
    }
}

extension HomeSectionListModel {
    struct Dependencies {
        let database: AppDatabase
    }
}

public extension HomeSectionListModel {
    func load() async {
        do {
            let order = try await dependencies.database.setting(.homeSections)
            let hidden = try await dependencies.database.setting(.homeHiddenSections)
            let layout = HomeLayout(order: order, hidden: hidden)

            state.layout = layout
            input.saved = .loaded(layout)
        } catch {
            state.notices.error.show(SettingMessage.loadFailed)
            input.saved = .failed
        }
    }

    func move(
        _ section: HomeSection,
        toSlot index: Int
    ) {
        state.layout.move(section, toSlot: index)
    }

    func startDragging(_ section: HomeSection) {
        guard state.dragging == nil else {
            return
        }

        let start = state.layout.slots.firstIndex(of: .section(section)) ?? 0

        state.dragging = Dragging(section: section, start: start)
    }

    func moveDragging(bySlots steps: Int) {
        guard let dragging = state.dragging else {
            return
        }

        move(dragging.section, toSlot: dragging.start + steps)
    }

    @discardableResult
    func finishDragging() -> Bool {
        guard state.dragging != nil else {
            return false
        }

        state.dragging = nil

        return true
    }

    func save() async {
        do {
            try await dependencies.database.setSetting(.homeSections, to: state.layout.order)
            try await dependencies.database.setSetting(.homeHiddenSections, to: state.layout.hidden)
            input.saved = .loaded(state.layout)
        } catch {
            state.notices.error.show(SettingMessage.saveFailed, for: error)
        }
    }
}

extension HomeSectionListModel: SettingsFoldModel {
    public func foldStore() -> SettingsFoldStore {
        SettingsFoldStore(dependencies.database)
    }
}
