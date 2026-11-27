import Core
import Foundation

extension RewardRuleDraft: IconBackedDraft {
    func newRecord(
        iconId: Icon.ID,
        sortOrder: Int,
        at now: Date
    ) throws -> RewardRule {
        try newRule(iconId: iconId, sortOrder: sortOrder, at: now)
    }
}
