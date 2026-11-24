import Core
import DesignSystem
import Store

@MainActor
public protocol SettingsEditRemoving: SettingsEditModel where Input: SettingsEditHidingInput {
    static var deleteFailedMessage: String { get }

    func remove(_ id: Input.EditingID) async throws -> Deletion
    func deleteFailedMessage(for error: any Error) -> String?

    func saveHidden(
        _ id: Input.EditingID,
        isHidden: Bool
    ) async throws
}

public extension SettingsEditRemoving {
    static var deleteFailedMessage: String {
        SettingsEditMessage.deleteFailed
    }

    var isHidden: Bool {
        input.isHidden
    }

    func deleteFailedMessage(for _: any Error) -> String? {
        nil
    }

    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId = input.editingId else {
            return false
        }

        do {
            try await saveHidden(editingId, isHidden: isHidden)
            return true
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }

    func delete() async -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        do {
            return try await remove(editingId)
        } catch {
            if let message = deleteFailedMessage(for: error) {
                state.errorNotice.show(message)
            } else {
                state.errorNotice.show(Self.deleteFailedMessage, for: error)
            }

            return nil
        }
    }
}
