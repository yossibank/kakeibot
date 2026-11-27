import Core
import DesignSystem
import Store

@MainActor
public protocol SettingsBoardModel: ScreenPerforming {
    associatedtype Item: Identifiable where Item.ID: Sendable
    associatedtype State: SettingsBoardState where State.ID == Item.ID
    associatedtype Output: SettingsBoardOutput where Output.Item == Item, Output.State == State

    var state: State { get }
    var output: Output { get }

    func load() async
    func reload() async
    func saveOrder(_ ids: [Item.ID]) async throws
    func remove(_ id: Item.ID) async throws -> Deletion
    func restoreRemoved(_ deletion: Deletion) async throws
    func hideFailedMessage(for error: any Error) -> String?
    func deleteFailedMessage(for error: any Error) -> String?
    func isInUse(_ error: any Error) -> Bool

    func saveHidden(
        _ id: Item.ID,
        isHidden: Bool
    ) async throws
}

public extension SettingsBoardModel {
    func reload() async {
        await load()
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
        var order = state.fields.movingOrder ?? output.shown.map(\.id)

        guard let from = order.firstIndex(of: id) else {
            return
        }

        let to = min(max(index, 0), order.count - 1)

        guard from != to else {
            return
        }

        order.remove(at: from)
        order.insert(id, at: to)
        state.setMovingOrder(order)
    }

    func cancelMoving() {
        state.setMovingOrder(nil)
    }

    func finishMoving() async {
        guard let movingOrder = state.fields.movingOrder else {
            return
        }

        do {
            try await saveOrder(movingOrder)
            await reload()
        } catch {
            state.notices.error.show(Self.saveFailedText, for: error)
        }

        state.setMovingOrder(nil)
    }

    @discardableResult
    func hide(_ id: Item.ID) async -> Bool {
        state.setMovingOrder(nil)

        do {
            try await saveHidden(id, isHidden: true)
            await reload()
            state.notices.removed.hidden.show(id)

            return true
        } catch {
            let message = hideFailedMessage(for: error) ?? Self.hideFailedText
            state.notices.error.show(message, for: error)
            return false
        }
    }

    func show(_ id: Item.ID) async {
        do {
            try await saveHidden(id, isHidden: false)
            await reload()
        } catch {
            state.notices.error.show(Self.showFailedText, for: error)
        }
    }

    @discardableResult
    func delete(_ id: Item.ID) async -> Deletion? {
        state.setMovingOrder(nil)

        do {
            let deletion = try await remove(id)

            await reload()
            state.notices.removed.deletion.show(deletion)

            return deletion
        } catch {
            let message = deleteFailedMessage(for: error) ?? Self.deleteFailedText

            state.notices.error.show(message, for: error)
            state.notices.removed.deletion.dismiss()

            return nil
        }
    }

    @discardableResult
    func deleteHidden() async -> SettingsBulkDelete {
        state.setMovingOrder(nil)

        let ids = output.hidden.map(\.id)

        let result = await SettingsBulkDelete.run(ids) { id in
            try await remove(id)
        } isInUse: { error in
            isInUse(error)
        }

        await reload()

        if let message = result.errorMessage {
            state.notices.error.show(message)
        } else if let message = result.infoMessage {
            state.notices.error.inform(message)
        }

        state.notices.removed.bulkDelete = result

        if let deletion = result.deletion {
            state.notices.removed.deletion.show(deletion)
        } else {
            state.notices.removed.deletion.dismiss()
        }

        return result
    }

    func receive(_ deletion: Deletion) {
        state.notices.removed.deletion.show(deletion)
    }

    func receiveHidden(_ id: Item.ID) {
        state.notices.removed.hidden.show(id)
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await restoreRemoved(deletion)
            await reload()
        } catch {
            state.notices.error.show(Self.restoreFailedText, for: error)
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
