import Core
import DesignSystem
import Observation
import Store

@MainActor
@Observable
public final class HomeSectionsModel {
    public private(set) var layout = HomeLayout.standard
    public private(set) var isLoaded = false

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension HomeSectionsModel {
    func load() async {
        do {
            let order = try await database.setting(.homeSections)
            let hidden = try await database.setting(.homeHiddenSections)

            layout = HomeLayout(order: order, hidden: hidden)
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }

        isLoaded = true
    }

    func move(
        _ section: HomeSection,
        to index: Int
    ) {
        layout.move(section, to: index)
    }

    func setHidden(
        _ section: HomeSection,
        _ isHidden: Bool
    ) async {
        layout.setHidden(section, isHidden)
        await save()
    }

    func save() async {
        do {
            try await database.setSetting(.homeSections, to: layout.order)
            try await database.setSetting(.homeHiddenSections, to: layout.hidden)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }
    }
}

private extension HomeSectionsModel {
    static let loadFailedMessage = "設定を読めませんでした"
    static let saveFailedMessage = "設定を保存できませんでした"
}
