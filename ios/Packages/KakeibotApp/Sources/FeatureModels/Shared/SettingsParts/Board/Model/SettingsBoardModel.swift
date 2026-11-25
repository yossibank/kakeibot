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
        var order = state.movingOrder ?? output.shown.map(\.id)

        guard let from = order.firstIndex(of: id) else {
            return
        }

        let to = min(max(index, 0), order.count - 1)

        guard from != to else {
            return
        }

        order.remove(at: from)
        order.insert(id, at: to)

        state.movingOrder = order
    }

    func cancelMoving() {
        state.movingOrder = nil
    }

    func finishMoving() async {
        guard let movingOrder = state.movingOrder else {
            return
        }

        do {
            try await saveOrder(movingOrder)
            await reload()
        } catch {
            state.errorNotice.show(Self.saveFailedText, for: error)
        }

        state.movingOrder = nil
    }

    @discardableResult
    func hide(_ id: Item.ID) async -> Bool {
        state.movingOrder = nil

        do {
            try await saveHidden(id, isHidden: true)
            await reload()

            state.removed.hiddenId = id

            return true
        } catch {
            let message = hideFailedMessage(for: error) ?? Self.hideFailedText
            state.errorNotice.show(message, for: error)
            return false
        }
    }

    func show(_ id: Item.ID) async {
        do {
            try await saveHidden(id, isHidden: false)
            await reload()
        } catch {
            state.errorNotice.show(Self.showFailedText, for: error)
        }
    }

    func delete(_ id: Item.ID) async -> Deletion? {
        state.movingOrder = nil

        do {
            let deletion = try await remove(id)
            await reload()

            state.removed.deletion = deletion

            return deletion
        } catch {
            let message = deleteFailedMessage(for: error) ?? Self.deleteFailedText
            state.errorNotice.show(message, for: error)
            state.removed.deletion = nil

            return nil
        }
    }

    func deleteHidden() async -> SettingsBulkDelete {
        state.movingOrder = nil

        let ids = output.hidden.map(\.id)

        let result = await SettingsBulkDelete.run(ids) { id in
            try await remove(id)
        } isInUse: { error in
            isInUse(error)
        }

        await reload()

        if let message = result.errorMessage {
            state.errorNotice.show(message)
        } else if let message = result.infoMessage {
            state.errorNotice.inform(message)
        }

        state.removed.bulkDelete = result
        state.removed.deletion = result.deletion

        return result
    }

    func restore(_ deletion: Deletion) async {
        do {
            try await restoreRemoved(deletion)
            await reload()
        } catch {
            state.errorNotice.show(Self.restoreFailedText, for: error)
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
