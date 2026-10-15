import SwiftUI

public struct TagLine<ID: Hashable>: View {
    let tags: [Item]
    let selection: ID?
    let onSelect: (ID) -> Void
    let onAdd: (() -> Void)?

    public init(
        _ tags: [Item],
        selection: ID?,
        onSelect: @escaping (ID) -> Void,
        onAdd: (() -> Void)? = nil
    ) {
        self.tags = tags
        self.selection = selection
        self.onSelect = onSelect
        self.onAdd = onAdd
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                ForEach(
                    Array(cards.enumerated()),
                    id: \.offset
                ) { index, card in
                    if index > 0 {
                        Spacer(minLength: Self.spacing)
                    }

                    hanging(card, at: index)
                }
            }
            .padding(.horizontal, Self.inset)

            ScrollView(.horizontal) {
                HStack(spacing: Self.spacing) {
                    ForEach(
                        Array(cards.enumerated()),
                        id: \.offset
                    ) { index, card in
                        hanging(card, at: index)
                    }
                }
                .padding(.horizontal, Self.inset)
                .padding(.bottom, Self.inset)
            }
            .scrollIndicators(.hidden)
        }
        .frame(height: Self.height, alignment: .top)
        .background(alignment: .top) {
            TagString()
                .stroke(Palette.gold.opacity(0.55), lineWidth: 0.8)
                .frame(height: Self.sag)
        }
        .sensoryFeedback(.selection, trigger: selection)
        .animation(.spring(duration: 0.35, bounce: 0.4), value: selection)
    }
}

public extension TagLine {
    struct Item: Identifiable {
        public let id: ID
        public let name: String

        public init(
            id: ID,
            name: String
        ) {
            self.id = id
            self.name = name
        }
    }
}

private extension TagLine {
    enum Card {
        case tag(Item)
        case add
    }

    static var height: CGFloat {
        54
    }

    static var sag: CGFloat {
        20
    }

    static var spacing: CGFloat {
        6
    }

    static var inset: CGFloat {
        6
    }

    static var tilts: [Double] {
        [-3, 2, -1, 3, -2]
    }

    var cards: [Card] {
        let add: [Card] = onAdd == nil ? [] : [.add]
        return tags.map(Card.tag) + add
    }

    var addTitle: String {
        tags.isEmpty ? "＋ タグ" : "＋"
    }

    func hanging(
        _ card: Card,
        at index: Int
    ) -> some View {
        let isSelected = isSelected(card)
        let tilt = isSelected ? 0 : Self.tilts[index % Self.tilts.count]

        return Button {
            tap(card)
        } label: {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Palette.gold.opacity(0.55))
                    .frame(width: 0.8, height: drop(at: index))

                TagCard(title(of: card), style: style(of: card))
            }
            .rotationEffect(.degrees(tilt), anchor: .top)
            .padding(.top, Self.inset)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func title(of card: Card) -> String {
        switch card {
        case let .tag(item): item.name
        case .add: addTitle
        }
    }

    func style(of card: Card) -> TagCard.Style {
        switch card {
        case .tag: isSelected(card) ? .selected : .plain
        case .add: .add
        }
    }

    func drop(at index: Int) -> CGFloat {
        let count = Double(max(cards.count, 1))
        let position = (Double(index) + 0.5) / count
        return 6 + 7 * sin(.pi * position)
    }

    func isSelected(_ card: Card) -> Bool {
        if case let .tag(item) = card {
            item.id == selection
        } else {
            false
        }
    }

    func tap(_ card: Card) {
        switch card {
        case let .tag(item):
            onSelect(item.id)
        case .add:
            onAdd?()
        }
    }
}

private struct TagString: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 4))

        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + 4),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )

        return path
    }
}

#Preview {
    @Previewable @State var selection: Int? = 1

    let tags = ["朝ごはん", "昼ごはん", "夜ごはん", "おやつ"].enumerated().map {
        TagLine<Int>.Item(id: $0.offset, name: $0.element)
    }

    VStack(spacing: 24) {
        TagLine(tags, selection: selection) { id in
            selection = selection == id ? nil : id
        } onAdd: {}

        TagLine<Int>([], selection: nil) { _ in
        } onAdd: {}
    }
    .padding()
    .background(Palette.night)
}
