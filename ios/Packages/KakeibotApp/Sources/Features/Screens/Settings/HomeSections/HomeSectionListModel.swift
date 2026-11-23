import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class HomeSectionListModel {
    public private(set) var layout = HomeLayout.standard
    public private(set) var isLoaded = false

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension HomeSectionListModel {
    func load() async {
        do {
            let order = try await database.setting(.homeSections)
            let hidden = try await database.setting(.homeHiddenSections)

            layout = HomeLayout(order: order, hidden: hidden)
        } catch {
            errorNotice.show(SettingMessage.loadFailed)
        }

        isLoaded = true
    }

    func move(
        _ section: HomeSection,
        toSlot index: Int
    ) {
        layout.move(section, toSlot: index)
    }

    func save() async {
        do {
            try await database.setSetting(.homeSections, to: layout.order)
            try await database.setSetting(.homeHiddenSections, to: layout.hidden)
        } catch {
            errorNotice.show(SettingMessage.saveFailed, for: error)
        }
    }
}

private extension HomeSectionListModel {}
