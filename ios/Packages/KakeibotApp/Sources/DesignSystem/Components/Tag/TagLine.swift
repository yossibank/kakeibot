import SwiftUI

public struct TagLine<ID: Hashable>: View {
    @State private var lift: Lift?
    @State private var frames: [ID: CGRect] = [:]
    @State private var liftCount = 0

    let tags: [Item]
    let selection: Set<ID>
    let onSelect: (ID) -> Void
    let onAdd: (() -> Void)?
    let onMove: ((ID, Int) -> Void)?

    public init(
        _ tags: [Item],
        selection: ID?,
        onSelect: @escaping (ID) -> Void,
        onAdd: (() -> Void)? = nil,
        onMove: ((ID, Int) -> Void)? = nil
    ) {
        self.init(
            tags,
            selection: Set([selection].compactMap(\.self)),
            onSelect: onSelect,
            onAdd: onAdd,
            onMove: onMove
        )
    }

    public init(
        _ tags: [Item],
        selection: Set<ID>,
        onSelect: @escaping (ID) -> Void,
        onAdd: (() -> Void)? = nil,
        onMove: ((ID, Int) -> Void)? = nil
    ) {
        self.tags = tags
        self.selection = selection
        self.onSelect = onSelect
        self.onAdd = onAdd
        self.onMove = onMove
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                ForEach(
                    Array(cards.enumerated()),
                    id: \.element.id
                ) { index, card in
                    if index > 0 {
                        Spacer(minLength: Self.spacing)
                    }

                    hanging(card, at: index)
                }
            }
            .coordinateSpace(.named(Self.space))
            .overlay(alignment: .topLeading) {
                liftedCard
            }
            .padding(.horizontal, Self.inset)

            ScrollView(.horizontal) {
                HStack(spacing: Self.spacing) {
                    ForEach(
                        Array(cards.enumerated()),
                        id: \.element.id
                    ) { index, card in
                        hanging(card, at: index)
                    }
                }
                .coordinateSpace(.named(Self.space))
                .overlay(alignment: .topLeading) {
                    liftedCard
                }
                .padding(.horizontal, Self.inset)
                .padding(.bottom, Self.inset)
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(lift != nil)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.height, alignment: .top)
        .background(alignment: .top) {
            TagString()
                .stroke(Palette.outline, lineWidth: 0.8)
                .frame(height: Self.sag)
        }
        .preference(key: TagLineMovingKey.self, value: lift != nil)
        .sensoryFeedback(.selection, trigger: selection)
        .sensoryFeedback(.impact(weight: .medium), trigger: liftCount)
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

extension TagLine {
    static func fits(
        _ names: [String],
        in width: CGFloat
    ) -> Bool {
        let cards = names.map { TagCard.width(of: $0) }.reduce(0, +)
        let gaps = spacing * CGFloat(max(names.count - 1, 0))
        return cards + gaps + inset * 2 <= width
    }
}

public struct TagLineMovingKey: PreferenceKey {
    public static let defaultValue = false

    public static func reduce(
        value: inout Bool,
        nextValue: () -> Bool
    ) {
        value = value || nextValue()
    }
}

private extension TagLine {
    @ViewBuilder
    var liftedCard: some View {
        if let lift, let frame = frames[lift.id] {
            let index = cards.firstIndex { $0.tagId == lift.id } ?? 0
            let item = tags.first { $0.id == lift.id }

            if let item {
                face(.tag(item), at: index, tilt: 0)
                    .scaleEffect(1.12, anchor: .top)
                    .shadow(
                        color: Palette.shadow.opacity(0.5),
                        radius: 10,
                        y: 6
                    )
                    .padding(.top, Self.inset)
                    .frame(
                        width: frame.width,
                        height: frame.height,
                        alignment: .top
                    )
                    .position(x: lift.start + lift.translation, y: frame.midY)
                    .allowsHitTesting(false)
            }
        }
    }

    func hanging(
        _ card: Card,
        at index: Int
    ) -> some View {
        let isLifted = card.tagId != nil && card.tagId == lift?.id
        let tilt = isSelected(card) ? 0 : Self.tilts[index % Self.tilts.count]

        return face(card, at: index, tilt: tilt)
            .opacity(isLifted ? 0 : 1)
            .padding(.top, Self.inset)
            .contentShape(.rect)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named(Self.space))
            } action: { frame in
                if let id = card.tagId {
                    frames[id] = frame
                }
            }
            .onTapGesture {
                tap(card)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    follow(card, to: location.x)
                } onEnd: {
                    drop()
                }
            )
    }

    func face(
        _ card: Card,
        at index: Int,
        tilt: Double
    ) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.outline)
                .frame(width: 0.8, height: drop(at: index))

            TagCard(title(of: card), style: style(of: card))
        }
        .rotationEffect(.degrees(tilt), anchor: .top)
    }
}

private extension TagLine {
    enum Card: Identifiable {
        case tag(Item)
        case add

        var id: CardID {
            switch self {
            case let .tag(item): .tag(item.id)
            case .add: .add
            }
        }

        var tagId: ID? {
            if case let .tag(item) = self {
                item.id
            } else {
                nil
            }
        }
    }

    enum CardID: Hashable {
        case tag(ID)
        case add
    }

    struct Lift {
        let id: ID
        let start: CGFloat
        let origin: CGFloat
        var translation: CGFloat
    }

    static var space: String {
        "TagLine"
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
        card.tagId.map(selection.contains) ?? false
    }

    func canMove(_ card: Card) -> Bool {
        onMove != nil && card.tagId != nil
    }

    func tap(_ card: Card) {
        switch card {
        case let .tag(item):
            onSelect(item.id)
        case .add:
            onAdd?()
        }
    }

    func drop() {
        withAnimation(.snappy) {
            lift = nil
        }
    }

    func follow(
        _ card: Card,
        to x: CGFloat
    ) {
        guard canMove(card), let id = card.tagId else {
            return
        }

        if lift == nil {
            let start = frames[id]?.midX ?? 0

            withAnimation(.snappy(duration: 0.2)) {
                lift = Lift(
                    id: id,
                    start: start,
                    origin: x,
                    translation: 0
                )
            }

            liftCount += 1
        }

        lift?.translation = x - (lift?.origin ?? x)

        guard let lift, let onMove else {
            return
        }

        let point = lift.start + lift.translation
        let others = tags.filter { $0.id != id }
        let target = others.count { (frames[$0.id]?.midX ?? 0) < point }
        let current = tags.firstIndex { $0.id == id }

        guard target != current else {
            return
        }

        withAnimation(.snappy) {
            onMove(id, target)
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
    @Previewable @State var names = ["朝ごはん", "昼ごはん", "夜ごはん", "おやつ"]
    @Previewable @State var selection: String?

    let tags = names.map { TagLine<String>.Item(id: $0, name: $0) }

    VStack(spacing: 24) {
        TagLine(tags, selection: selection) { id in
            selection = selection == id ? nil : id
        } onAdd: {} onMove: { id, index in
            names.removeAll { $0 == id }
            names.insert(id, at: index)
        }

        TagLine<String>([], selection: nil) { _ in
        } onAdd: {}
    }
    .padding()
    .background(Palette.background)
}
