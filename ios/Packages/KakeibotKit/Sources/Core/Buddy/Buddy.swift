import Foundation

public enum Buddy: String, CaseIterable, Sendable {
    case rabbit
    case panda
    case pig
    case penguin
    case monkey
    case elephant
    case giraffe
    case hippo
    case parrot
    case snake
}

public extension Buddy {
    var defaultName: String {
        switch self {
        case .rabbit: "うさぎ"
        case .panda: "パンダ"
        case .pig: "ぶた"
        case .penguin: "ペンギン"
        case .monkey: "さる"
        case .elephant: "ぞう"
        case .giraffe: "きりん"
        case .hippo: "かば"
        case .parrot: "オウム"
        case .snake: "へび"
        }
    }

    func name(_ customName: String) -> String {
        let trimmed = customName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultName : trimmed
    }
}
