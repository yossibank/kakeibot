import Observation

@MainActor
public protocol SettingsEditState: NoticeHolding, Observable {
    var prompt: SettingsEditPrompt { get set }
}
