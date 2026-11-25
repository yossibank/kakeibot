import Observation

@MainActor
public protocol SettingsEditState: NoticeHolding, Observable {
    associatedtype Saved: Sendable
    associatedtype Panel: Hashable & Sendable

    var prompt: SettingsEditPrompt<Panel> { get set }
    var outcome: ScreenOutcome<SettingsEditOutcome<Saved>> { get set }
}

public extension SettingsEditState {
    func open(_ panel: Panel) {
        if prompt.panel != panel {
            prompt.panel = panel
        }
    }

    func closePanel() {
        if prompt.panel != nil {
            prompt.panel = nil
        }
    }
}
