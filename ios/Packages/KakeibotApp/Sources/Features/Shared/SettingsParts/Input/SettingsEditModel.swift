import DesignSystem
import Store

@MainActor
protocol SettingsEditModel: AnyObject {
    associatedtype Edited: Equatable
    associatedtype EditingID

    var edited: Edited { get }
    var baseline: Edited? { get }
    var editingId: EditingID? { get }
    var problemMessage: String? { get }
}

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

enum SettingsEditMessage {
    static let saveFailed = "保存できませんでした"
    static let deleteFailed = "削除できませんでした"
}

extension SettingsEditModel {
    var isEditing: Bool {
        editingId != nil
    }

    var isChanged: Bool {
        baseline.map { $0 != edited } ?? false
    }

    var canSave: Bool {
        problemMessage == nil
    }

    var saveTitle: String {
        SettingsSaveTitle.text(problem: problemMessage, isEditing: isEditing)
    }
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
