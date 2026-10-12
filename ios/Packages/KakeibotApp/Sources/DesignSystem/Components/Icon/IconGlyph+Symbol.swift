import Core

public extension Icon.Glyph {
    var symbolName: String {
        switch self {
        case .food: "fork.knife"
        case .daily: "basket"
        case .transit: "tram"
        case .social: "wineglass"
        case .hobby: "gamecontroller"
        case .clothes: "tshirt"
        case .beauty: "sparkles"
        case .medical: "cross.case"
        case .home: "house"
        case .phone: "iphone"
        case .utility: "bolt"
        case .salary: "yensign"
        case .bonus: "gift"
        case .other: "ellipsis"
        case .cash: "wallet.bifold"
        case .bank: "building.columns"
        }
    }
}
