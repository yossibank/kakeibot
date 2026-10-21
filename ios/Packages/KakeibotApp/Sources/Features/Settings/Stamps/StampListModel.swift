import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class StampListModel: ScreenModel {
    public private(set) var shelf: IconShelf?
    public private(set) var movingOrder: [ShelfIcon.ID]?

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension StampListModel {
    var shown: [ShelfIcon] {
        let stamps = stamps(isHidden: false)

        guard let movingOrder else {
            return stamps
        }

        return movingOrder.compactMap { id in
            stamps.first { $0.id == id }
        }
    }

    var hidden: [ShelfIcon] {
        stamps(isHidden: true)
    }

    func icon(for shelfIcon: ShelfIcon) -> Icon? {
        shelf?.icons[shelfIcon.iconId]
    }

    func load() async {
        do {
            shelf = try await database.iconShelf()
        } catch {
            errorNotice.show(Self.loadFailedMessage)
        }
    }

    func observe() async {
        await observe(
            database.iconShelfUpdates(),
            failure: Self.loadFailedMessage
        ) { shelf in
            self.shelf = shelf
        }
    }

    func move(
        _ id: ShelfIcon.ID,
        to index: Int
    ) {
        var order = movingOrder ?? shown.map(\.id)

        guard let from = order.firstIndex(of: id) else {
            return
        }

        let to = min(max(index, 0), order.count - 1)

        guard from != to else {
            return
        }

        order.remove(at: from)
        order.insert(id, at: to)
        movingOrder = order
    }

    func cancelMoving() {
        movingOrder = nil
    }

    @discardableResult
    func hide(_ id: ShelfIcon.ID) async -> Bool {
        movingOrder = nil
        let failure = Self.hideFailedMessage
        return await setHidden(id, isHidden: true, failure: failure)
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await database.restore(deletion)
            await load()
        } catch {
            errorNotice.show(Self.restoreFailedMessage)
        }
    }

    func show(_ id: ShelfIcon.ID) async {
        await setHidden(id, isHidden: false, failure: Self.showFailedMessage)
    }

    func finishMoving() async {
        guard let movingOrder else {
            return
        }

        let ids = movingOrder + hidden.map(\.id)

        do {
            try await database.reorderShelfIcons(ids, at: Date())
            await load()
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }

        self.movingOrder = nil
    }
}

private extension StampListModel {
    static let loadFailedMessage = "スタンプを読めませんでした"
    static let saveFailedMessage = "並びを保存できませんでした"
    static let hideFailedMessage = "非表示にできませんでした"
    static let showFailedMessage = "表示に戻せませんでした"
    static let restoreFailedMessage = "元に戻せませんでした"

    func stamps(isHidden: Bool) -> [ShelfIcon] {
        let stamps = shelf?.shelfIcons ?? []
        return stamps.filter { ($0.archivedAt != nil) == isHidden }
    }

    @discardableResult
    func setHidden(
        _ id: ShelfIcon.ID,
        isHidden: Bool,
        failure: String
    ) async -> Bool {
        do {
            try await database.setShelfIconHidden(
                id,
                isHidden: isHidden,
                at: Date()
            )

            await load()

            return true
        } catch {
            errorNotice.show(failure)
            return false
        }
    }
}
