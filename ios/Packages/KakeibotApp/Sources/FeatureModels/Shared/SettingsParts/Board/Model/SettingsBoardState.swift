import Observation

@MainActor
public protocol SettingsBoardState: NoticesHolding, Observable
    where Notices == SettingsBoardNotices<ID> {
    associatedtype ID: Hashable & Sendable
    associatedtype Destination: Hashable & Sendable
    associatedtype Fields: SettingsBoardFields where Fields.ID == ID

    var fields: Fields { get set }
    var presented: SettingsBoardShown<ID, Destination> { get set }
}

public extension SettingsBoardState {
    func setMovingOrder(_ order: [ID]?) {
        fields.movingOrder = order
    }

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
