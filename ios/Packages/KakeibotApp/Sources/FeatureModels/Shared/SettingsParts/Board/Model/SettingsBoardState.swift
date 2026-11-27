import Observation

@MainActor
public protocol SettingsBoardState: NoticesHolding, Observable
    where Notices == SettingsBoardNotices<ID> {
    associatedtype ID: Hashable & Sendable
    associatedtype Destination: Hashable & Sendable

    var movingOrder: [ID]? { get }
    var presented: SettingsBoardShown<ID, Destination> { get set }

    func setMovingOrder(_ order: [ID]?)
}

public extension SettingsBoardState {
    func open(_ destination: Destination) {
        if presented.destination != destination {
            presented.destination = destination
        }
    }

    func ask(_ prompt: SettingsBoardPrompt<ID>) {
        if presented.prompt != prompt {
            presented.prompt = prompt
        }
    }

    func closePrompt(_ prompt: SettingsBoardPrompt<ID>) {
        if presented.prompt == prompt {
            presented.prompt = nil
        }
    }
}
