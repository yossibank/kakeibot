import Store

public extension SyncStatus {
    var troubleTitle: String? {
        if isEnabled {
            return sendProblem == nil ? nil : "送れていません"
        }

        return stopReason == nil ? nil : "切れました"
    }

    var troubleMessage: String? {
        isEnabled ? sendProblem?.message : stopReason?.message
    }

    var hasTrouble: Bool {
        troubleTitle != nil
    }
}
