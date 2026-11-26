import SwiftUI

extension TagLine {
    enum Card {
        case tag(Item)
        case add
        case edit
    }

    enum CardID: Hashable {
        case tag(ID)
        case add
        case edit
    }

    struct Lift {
        let id: ID
        let start: CGFloat
        let origin: CGFloat

        var translation: CGFloat
    }
}

extension TagLine {
    nonisolated static var space: String {
        "TagLine"
    }

    static var height: CGFloat {
        54
    }

    static var sag: CGFloat {
        20
    }

    static var spacing: CGFloat {
        8
    }

    static var inset: CGFloat {
        4
    }

    static var tilts: [Double] {
        [-3, 2, -1, 3, -2]
    }

    var cards: [Card] {
        let add: [Card] = onAdd == nil ? [] : [.add]
        let edit: [Card] = onEdit == nil ? [] : [.edit]
        return tags.map(Card.tag) + add + edit
    }

    var addTitle: String {
        tags.isEmpty ? "＋ タグ" : "＋"
    }

    static func fits(
        _ names: [String],
        in width: CGFloat
    ) -> Bool {
        let cards = names.map { TagCard.width(of: $0) }.reduce(0, +)
        let gaps = spacing * CGFloat(max(names.count - 1, 0))
        return cards + gaps + inset * 2 <= width
    }

    func title(of card: Card) -> String {
        switch card {
        case let .tag(item): item.name
        case .add: addTitle
        case .edit: "編集"
        }
    }

    func style(of card: Card) -> TagCard.Style {
        switch card {
        case .tag: isSelected(card) ? .selected : .plain
        case .add, .edit: .add
        }
    }

    func drop(at index: Int) -> CGFloat {
        let count = Double(max(cards.count, 1))
        let position = (Double(index) + 0.5) / count
        return 6 + 7 * sin(.pi * position)
    }

    func isSelected(_ card: Card) -> Bool {
        card.tagId.map(selection.contains) ?? false
    }

    func canMove(_ card: Card) -> Bool {
        onMove != nil && card.tagId != nil
    }
}

extension TagLine.Card {
    var tagId: ID? {
        if case let .tag(item) = self {
            item.id
        } else {
            nil
        }
    }
}

extension TagLine.Card: Identifiable {
    var id: TagLine.CardID {
        switch self {
        case let .tag(item): .tag(item.id)
        case .add: .add
        case .edit: .edit
        }
    }
}
