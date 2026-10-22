import Foundation

public enum Buddy: String, CaseIterable, Sendable {
    case dial
    case cat
    case rabbit
    case bear
}

public extension Buddy {
    var defaultName: String {
        switch self {
        case .dial: "まる"
        case .cat: "たま"
        case .rabbit: "うさ"
        case .bear: "くま"
        }
    }

    func name(_ customName: String) -> String {
        let trimmed = customName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultName : trimmed
    }
}
