import Store

struct SettingsBulkDelete {
    let deletion: Deletion?
    let keptCount: Int
    let hasFailed: Bool
}

extension SettingsBulkDelete {
    var message: String? {
        if hasFailed {
            return "削除できないものがありました"
        }

        guard keptCount > 0 else {
            return nil
        }

        return "記録がある \(keptCount) 件は残しました"
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
