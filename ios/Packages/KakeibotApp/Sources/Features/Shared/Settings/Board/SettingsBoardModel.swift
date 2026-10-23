import DesignSystem
import Store

@MainActor
public protocol SettingsBoardModel: AnyObject {
    associatedtype Item: Identifiable where Item.ID: Sendable

    var movingOrder: [Item.ID]? { get set }
    var errorNotice: ErrorNotice { get set }
    var visible: [Item] { get }
    var hidden: [Item] { get }

    func reload() async
    func saveOrder(_ ids: [Item.ID]) async throws
    func saveHidden(
        _ id: Item.ID,
        isHidden: Bool
    ) async throws
    func remove(_ id: Item.ID) async throws -> Deletion
    func restoreRemoved(_ deletion: Deletion) async throws
    func hideFailedMessage(for error: any Error) -> String?
    func deleteFailedMessage(for error: any Error) -> String?
    func isInUse(_ error: any Error) -> Bool
}

public extension SettingsBoardModel {
    var shown: [Item] {
        let visible = visible

        guard let movingOrder else {
            return visible
        }

        return movingOrder.compactMap { id in
            visible.first { $0.id == id }
        }
    }

    func hideFailedMessage(for _: any Error) -> String? {
        nil
    }

    func deleteFailedMessage(for _: any Error) -> String? {
        nil
    }

    func isInUse(_: any Error) -> Bool {
        false
    }

    func move(
        _ id: Item.ID,
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

    func finishMoving() async {
        guard let movingOrder else {
            return
        }

        do {
            try await saveOrder(movingOrder)
            await reload()
        } catch {
            errorNotice.show(Self.saveFailedText)
        }

        self.movingOrder = nil
    }

    @discardableResult
    func hide(_ id: Item.ID) async -> Bool {
        movingOrder = nil

        do {
            try await saveHidden(id, isHidden: true)
            await reload()

            return true
        } catch {
            let message = hideFailedMessage(for: error) ?? Self.hideFailedText

            errorNotice.show(message)

            return false
        }
    }

    func show(_ id: Item.ID) async {
        do {
            try await saveHidden(id, isHidden: false)
            await reload()
        } catch {
            errorNotice.show(Self.showFailedText)
        }
    }

    func delete(_ id: Item.ID) async -> Deletion? {
        movingOrder = nil

        do {
            let deletion = try await remove(id)

            await reload()

            return deletion
        } catch {
            let message = deleteFailedMessage(for: error)
                ?? Self.deleteFailedText

            errorNotice.show(message)

            return nil
        }
    }

    func deleteHidden() async -> Deletion? {
        let ids = hidden.map(\.id)

        movingOrder = nil

        let result = await SettingsBulkDelete.run(ids) { id in
            try await remove(id)
        } isInUse: { error in
            isInUse(error)
        }

        await reload()

        if let message = result.message {
            errorNotice.show(message)
        }

        return result.deletion
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await restoreRemoved(deletion)
            await reload()
        } catch {
            errorNotice.show(Self.restoreFailedText)
        }
    }
}

private extension SettingsBoardModel {
    static var hideFailedText: String {
        "非表示にできませんでした"
    }

    static var deleteFailedText: String {
        "削除できませんでした"
    }

    static var saveFailedText: String {
        "並びを保存できませんでした"
    }

    static var showFailedText: String {
        "表示に戻せませんでした"
    }

    static var restoreFailedText: String {
        "元に戻せませんでした"
    }
}
