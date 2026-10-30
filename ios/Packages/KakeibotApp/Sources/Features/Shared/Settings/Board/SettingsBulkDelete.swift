import Store

public struct SettingsBulkDelete: Sendable {
    public let deletion: Deletion?
    public let keptCount: Int
    public let hasFailed: Bool
}

public extension SettingsBulkDelete {
    func note(for deletion: Deletion?) -> String? {
        guard
            keptCount > 0,
            let deletion,
            deletion.id == self.deletion?.id
        else {
            return nil
        }

        return "記録がある \(keptCount) 件は残しました"
    }
}

extension SettingsBulkDelete {
    static let failedMessage = "削除できないものがありました"
    static let allKeptMessage = "記録があるので削除しませんでした"

    var errorMessage: String? {
        hasFailed ? Self.failedMessage : nil
    }

    var infoMessage: String? {
        guard
            !hasFailed,
            deletion == nil,
            keptCount > 0
        else {
            return nil
        }

        return Self.allKeptMessage
    }

    @MainActor
    static func run<ID: Sendable>(
        _ ids: [ID],
        delete: (ID) async throws -> Deletion,
        isInUse: (any Error) -> Bool = { _ in false }
    ) async -> SettingsBulkDelete {
        var deletions: [Deletion] = []
        var keptCount = 0
        var hasFailed = false

        for id in ids {
            do {
                let deletion = try await delete(id)
                deletions.append(deletion)
            } catch where isInUse(error) {
                keptCount += 1
            } catch {
                hasFailed = true
            }
        }

        let deletion = deletions.isEmpty ? nil : Deletion(merging: deletions)

        return SettingsBulkDelete(
            deletion: deletion,
            keptCount: keptCount,
            hasFailed: hasFailed
        )
    }
}
