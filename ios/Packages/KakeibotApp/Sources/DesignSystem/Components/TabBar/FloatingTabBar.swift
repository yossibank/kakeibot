import SwiftUI

public struct FloatingTabBar<Value: Hashable>: View {
    @Binding var selection: Value

    @State private var barWidth: CGFloat = 0
    @State private var dragX: CGFloat?
    @State private var addCount = 0

    let items: [Item]
    let onAdd: () -> Void

    public init(
        selection: Binding<Value>,
        items: [Item],
        onAdd: @escaping () -> Void
    ) {
        _selection = selection
        self.items = items
        self.onAdd = onAdd
    }

    public var body: some View {
        HStack(spacing: 12) {
            tabs
            addButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}

public extension FloatingTabBar {
    struct Item {
        public let title: String
        public let systemImage: String
        public let value: Value

        public init(
            _ title: String,
            systemImage: String,
            value: Value
        ) {
            self.title = title
            self.systemImage = systemImage
            self.value = value
        }
    }

    static var height: CGFloat {
        64
    }
}

private extension FloatingTabBar {
    var tabs: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                tabItem(item, isHighlighted: index == highlightedIndex)
            }
        }
        .background(alignment: .leading) {
            indicator
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            barWidth = width
        }
        .contentShape(Capsule())
        .gesture(dragGesture)
        .sensoryFeedback(.selection, trigger: highlightedIndex)
        .padding(6)
        .background {
            Capsule()
                .fill(Self.sheen)
        }
        .overlay {
            Capsule()
                .strokeBorder(Self.rim, lineWidth: 1)
        }
        .glass(tint: nil, in: Capsule())
    }

    var indicator: some View {
        let isDragging = dragX != nil
        let fill = Palette.gold.opacity(isDragging ? 0.2 : 0.12)
        let scale: CGFloat = isDragging ? 1.08 : 1
        let opacity: Double = barWidth > 0 ? 1 : 0

        return Capsule()
            .fill(fill)
            .overlay {
                Capsule()
                    .strokeBorder(Self.indicatorRim, lineWidth: 0.8)
            }
            .frame(width: itemWidth, height: Self.height - 12)
            .scaleEffect(scale)
            .offset(x: indicatorX)
            .opacity(opacity)
    }

    var addButton: some View {
        Button {
            addCount += 1
            onAdd()
        } label: {
            ZStack {
                DialTicks(count: 12, length: 4)
                    .stroke(Palette.gold.opacity(0.7), lineWidth: 1)
                    .padding(8)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .ultraLight))
                    .foregroundStyle(Palette.champagne)
            }
            .frame(width: Self.height, height: Self.height)
            .background {
                Circle()
                    .fill(Self.sheen)
            }
            .overlay {
                Circle()
                    .strokeBorder(Self.goldRing, lineWidth: 1.2)
            }
            .contentShape(Circle())
        }
        .buttonStyle(PressStyle())
        .glass(tint: Palette.nightTop.opacity(0.85), in: Circle())
        .shadow(color: Palette.gold.opacity(0.3), radius: 14, y: 4)
        .sensoryFeedback(.impact(weight: .light), trigger: addCount)
    }

    func tabItem(
        _ item: Item,
        isHighlighted: Bool
    ) -> some View {
        let iconColor = isHighlighted ? Palette.gold : Palette.mist
        let titleColor = isHighlighted ? Palette.champagne : Palette.mist

        return VStack(spacing: 3) {
            Image(systemName: item.systemImage)
                .font(.system(size: 19, weight: .light))
                .foregroundStyle(iconColor)

            Text(item.title)
                .font(.system(size: 10))
                .tracking(0.6)
                .foregroundStyle(titleColor)
        }
        .frame(maxWidth: .infinity, minHeight: Self.height - 12)
        .contentShape(Capsule())
    }
}

private extension FloatingTabBar {
    static var sheen: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.14), .white.opacity(0)],
            startPoint: .top,
            endPoint: .center
        )
    }

    static var rim: LinearGradient {
        LinearGradient(
            colors: [Palette.gold.opacity(0.85), Palette.gold.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var indicatorRim: LinearGradient {
        LinearGradient(
            colors: [
                Palette.champagne.opacity(0.7),
                Palette.gold.opacity(0.25)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var goldRing: AngularGradient {
        AngularGradient(
            colors: [
                Palette.champagne,
                Palette.gold,
                Palette.bronze,
                Palette.gold,
                Palette.champagne
            ],
            center: .center
        )
    }

    var itemWidth: CGFloat {
        items.isEmpty ? 0 : barWidth / CGFloat(items.count)
    }

    var selectedIndex: Int {
        items.firstIndex { $0.value == selection } ?? 0
    }

    var highlightedIndex: Int {
        dragX.map(index(at:)) ?? selectedIndex
    }

    var indicatorX: CGFloat {
        guard let dragX else {
            return itemWidth * CGFloat(selectedIndex)
        }

        let maxX = barWidth - itemWidth
        return min(max(dragX - itemWidth / 2, 0), maxX)
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                withAnimation(.interactiveSpring) {
                    dragX = value.location.x
                }
            }
            .onEnded { value in
                let index = index(at: value.location.x)

                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    dragX = nil
                    selection = items[index].value
                }
            }
    }

    func index(at x: CGFloat) -> Int {
        guard itemWidth > 0 else {
            return selectedIndex
        }

        let index = Int((x / itemWidth).rounded(.down))
        return min(max(index, 0), items.count - 1)
    }
}

private struct PressStyle: ButtonStyle {
    static var usesGlass: Bool {
        if #available(iOS 26, *) {
            true
        } else {
            false
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        let isShrinking = configuration.isPressed && !Self.usesGlass
        let scale: CGFloat = isShrinking ? 0.92 : 1

        return configuration.label
            .scaleEffect(scale)
            .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

#Preview {
    @Previewable @State var selection = 0

    let items: [FloatingTabBar<Int>.Item] = [
        .init("ホーム", systemImage: "house", value: 0),
        .init("記録", systemImage: "calendar", value: 1),
        .init("振り返り", systemImage: "chart.pie", value: 2),
        .init("資産", systemImage: "building.columns", value: 3)
    ]

    VStack {
        Spacer()

        FloatingTabBar(
            selection: $selection,
            items: items
        ) {}
    }
    .background(Palette.night)
}
