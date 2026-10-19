import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class ShelfIconListModel: ScreenModel {
    public private(set) var shelf: IconShelf?
    public private(set) var movingOrder: [ShelfIcon.ID]?

    public internal(set) var errorNotice = ErrorNotice()

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }
}

public extension ShelfIconListModel {
    var shown: [ShelfIcon] {
        let shelfIcons = shelf?.shelfIcons ?? []

        guard let movingOrder else {
            return shelfIcons
        }

        return movingOrder.compactMap { id in
            shelfIcons.first { $0.id == id }
        }
    }

    func icon(for shelfIcon: ShelfIcon) -> Icon? {
        shelf?.icons[shelfIcon.iconId]
    }

    func load() async {
        do {
            shelf = try await database.iconShelf()
        } catch {
            errorNotice.show(IconEditModel.shelfLoadFailedMessage)
        }
    }

    func observe() async {
        await observe(
            database.iconShelfUpdates(),
            failure: IconEditModel.shelfLoadFailedMessage
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

    func remove(_ id: ShelfIcon.ID) async {
        movingOrder = nil

        do {
            try await database.removeShelfIcon(id, at: Date())
            await load()
        } catch {
            errorNotice.show(Self.removeFailedMessage)
        }
    }

    func finishMoving() async {
        guard let movingOrder else {
            return
        }

        do {
            try await database.reorderShelfIcons(movingOrder, at: Date())
            await load()
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }

        self.movingOrder = nil
    }
}

private extension ShelfIconListModel {
    static let saveFailedMessage = "並びを保存できませんでした"
    static let removeFailedMessage = "棚から消せませんでした"
}
