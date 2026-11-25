import Observation

@MainActor
public protocol SettingsBoardState: NoticeHolding, Observable {
    associatedtype ID: Hashable & Sendable
    associatedtype Destination: Hashable & Sendable

    var movingOrder: [ID]? { get set }
    var removed: SettingsBoardRemoved<ID> { get set }
    var shown: SettingsBoardShown<ID, Destination> { get set }
}

public extension SettingsBoardState {
    func open(_ destination: Destination) {
        if shown.destination != destination {
            shown.destination = destination
        }
    }

    func ask(_ prompt: SettingsBoardPrompt<ID>) {
        if shown.prompt != prompt {
            shown.prompt = prompt
        }
    }

    func closePrompt(_ prompt: SettingsBoardPrompt<ID>) {
        if shown.prompt == prompt {
            shown.prompt = nil
        }
    }
}
