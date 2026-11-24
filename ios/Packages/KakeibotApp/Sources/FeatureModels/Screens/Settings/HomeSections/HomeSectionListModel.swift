import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class HomeSectionListModel {
    public let state = State()
    public let input = Input()

    let dependencies: Dependencies

    public init(parts: ScreenParts) {
        self.dependencies = Dependencies(database: parts.database)
    }
}

public extension HomeSectionListModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var errorNotice = ErrorNotice()

        public internal(set) var layout = HomeLayout.standard
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var isLoaded = false
    }

    func load() async {
        do {
            let order = try await dependencies.database.setting(.homeSections)
            let hidden = try await dependencies.database.setting(.homeHiddenSections)

            state.layout = HomeLayout(order: order, hidden: hidden)
        } catch {
            state.errorNotice.show(SettingMessage.loadFailed)
        }

        input.isLoaded = true
    }

    func move(
        _ section: HomeSection,
        toSlot index: Int
    ) {
        state.layout.move(section, toSlot: index)
    }

    func save() async {
        do {
            try await dependencies.database.setSetting(.homeSections, to: state.layout.order)
            try await dependencies.database.setSetting(.homeHiddenSections, to: state.layout.hidden)
        } catch {
            state.errorNotice.show(SettingMessage.saveFailed, for: error)
        }
    }
}

extension HomeSectionListModel {
    struct Dependencies {
        let database: AppDatabase
    }
}
