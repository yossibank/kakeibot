import DesignSystem
import Store

@MainActor
protocol SettingsEditRemoving: SettingsEditModel {
    static var deleteFailedMessage: String { get }

    var isHidden: Bool { get set }
    var errorNotice: ErrorNotice { get set }

    func remove(_ id: EditingID) async throws -> Deletion
    func deleteFailedMessage(for error: any Error) -> String?

    func saveHidden(
        _ id: EditingID,
        isHidden: Bool
    ) async throws
}

extension SettingsEditRemoving {
    static var deleteFailedMessage: String {
        SettingsEditMessage.deleteFailed
    }

    func deleteFailedMessage(for _: any Error) -> String? {
        nil
    }

    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId else {
            return false
        }

        do {
            try await saveHidden(editingId, isHidden: isHidden)

            self.isHidden = isHidden

            return true
        } catch {
            errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }

    func delete() async -> Deletion? {
        guard let editingId else {
            return nil
        }

        do {
            return try await remove(editingId)
        } catch {
            if let message = deleteFailedMessage(for: error) {
                errorNotice.show(message)
            } else {
                errorNotice.show(Self.deleteFailedMessage, for: error)
            }

            return nil
        }
    }
}
