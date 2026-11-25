import Observation

@MainActor
public protocol SettingsEditState: NoticeHolding, Observable {
    associatedtype Saved: Sendable

    var prompt: SettingsEditPrompt { get set }
    var outcome: ScreenOutcome<SettingsEditOutcome<Saved>> { get set }
}
