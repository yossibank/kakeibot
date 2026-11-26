import Core

@MainActor
protocol EditFlowSource<Saved>: AnyObject {
    associatedtype Saved: Sendable
    associatedtype State: NoticeHolding

    var state: State { get }
    var isEditing: Bool { get }
    var isChanged: Bool { get }
    var problem: String? { get }
    var readyTitle: String { get }
    var isHidden: Bool { get }
    var asksBeforeHiding: Bool { get }

    func rest() -> Bool
    func store() async -> Saved?
    func keepsOpen(after saved: Saved) -> Bool
    func storeHidden(_ isHidden: Bool) async throws
    func remove() async throws -> Deletion?
    func hideFailedMessage(for error: any Error) -> String
    func deleteFailedMessage(for error: any Error) -> String
}

extension EditFlowSource {
    var readyTitle: String {
        isEditing ? "変更を保存" : "追加する"
    }

    var isHidden: Bool {
        false
    }

    var asksBeforeHiding: Bool {
        false
    }

    func rest() -> Bool {
        false
    }

    func keepsOpen(after _: Saved) -> Bool {
        false
    }

    func storeHidden(_: Bool) async throws {}

    func remove() async throws -> Deletion? {
        nil
    }

    func hideFailedMessage(for _: any Error) -> String {
        SettingsEditMessage.saveFailed
    }

    func deleteFailedMessage(for _: any Error) -> String {
        SettingsEditMessage.deleteFailed
    }
}
