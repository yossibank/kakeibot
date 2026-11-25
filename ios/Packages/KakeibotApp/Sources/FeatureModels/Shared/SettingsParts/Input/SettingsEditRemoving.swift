import Core
import DesignSystem
import Store

@MainActor
public protocol SettingsEditRemoving: SettingsEditModel
    where Input: SettingsEditHidingInput, State: SettingsEditState {
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

    @discardableResult
    func setHidden(_ isHidden: Bool) async -> Bool {
        guard let editingId = input.editingId else {
            return false
        }

        do {
            try await saveHidden(editingId, isHidden: isHidden)
            state.outcome.send(SettingsEditOutcome(isHidden: isHidden))
            return true
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            return false
        }
    }

    func saveTogglingHidden(_ save: @MainActor (Self) async -> Void) async {
        state.prompt.togglesHiddenAfterSave = true

        await save(self)

        state.prompt.togglesHiddenAfterSave = false
    }

    @discardableResult
    func delete() async -> Deletion? {
        guard let editingId = input.editingId else {
            return nil
        }

        do {
            let deletion = try await remove(editingId)
            state.outcome.send(SettingsEditOutcome(deletion: deletion))
            return deletion
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

extension SettingsEditRemoving {
    func finishSave(_ saved: State.Saved) async {
        guard
            state.prompt.togglesHiddenAfterSave,
            let editingId = input.editingId
        else {
            state.outcome.send(SettingsEditOutcome(saved: saved))
            return
        }

        state.prompt.togglesHiddenAfterSave = false

        let isHidden = !input.isHidden

        do {
            try await saveHidden(editingId, isHidden: isHidden)
            state.outcome.send(SettingsEditOutcome(saved: saved, isHidden: isHidden))
        } catch {
            state.errorNotice.show(SettingsEditMessage.saveFailed, for: error)
            state.outcome.send(SettingsEditOutcome(saved: saved, closes: false))
        }
    }
}

extension SettingsEditRemoving where State.Saved == Void {
    func finishSave() async {
        await finishSave(())
    }
}
