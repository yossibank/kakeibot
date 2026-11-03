import SwiftUI

public struct FloatingTabBar<Value: Hashable>: View {
    @Binding var selection: Value

    @State private var barWidth: CGFloat = 0
    @State private var dragX: CGFloat?
    @State private var addCount = 0

    @Environment(\.themeStyle.decorations) private var hasDecorations
    @Environment(\.themeStyle.showsTabTitles) private var showsTitles

    let items: [Item]
    let isAddHinted: Bool
    let onAdd: () -> Void

    public init(
        selection: Binding<Value>,
        items: [Item],
        isAddHinted: Bool = false,
        onAdd: @escaping () -> Void
    ) {
        _selection = selection

        self.items = items
        self.isAddHinted = isAddHinted
        self.onAdd = onAdd
    }

    public var body: some View {
        HStack(spacing: 12) {
            tabs

            addButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, Self.bottomGap)
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

    static var clearance: CGFloat {
        height + bottomGap
    }
}

private extension FloatingTabBar {
    var tabs: some View {
        let indexedItems = Array(items.enumerated())

        return HStack(spacing: 0) {
            ForEach(indexedItems, id: \.offset) { index, item in
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
        .haptic(.selection, trigger: highlightedIndex)
        .padding(8)
        .background {
            Capsule()
                .fill(TabBarStyle.sheen)
        }
        .overlay {
            Capsule()
                .strokeBorder(TabBarStyle.rim, lineWidth: 1)
        }
        .glass(tint: Palette.backgroundBottom.opacity(.medium), in: Capsule())
    }

    var indicator: some View {
        let isDragging = dragX != nil
        let fill = Palette.accent.opacity(isDragging ? .soft : .subtle)
        let scale: CGFloat = isDragging ? 1.08 : 1
        let isShown = barWidth > 0 && highlightedIndex != nil
        let opacity: Double = isShown ? 1 : 0

        return Capsule()
            .fill(fill)
            .overlay {
                Capsule()
                    .strokeBorder(TabBarStyle.indicatorRim, lineWidth: 0.8)
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
                    .stroke(Palette.accent.opacity(.strong), lineWidth: 1)
                    .padding(8)

                Image(systemName: "plus")
                    .sansFont(.headline, weight: .ultraLight)
                    .foregroundStyle(Palette.accentStrong)
            }
            .frame(width: Self.height, height: Self.height)
            .background {
                Circle()
                    .fill(TabBarStyle.sheen)
            }
            .overlay {
                Circle()
                    .strokeBorder(TabBarStyle.ring(hasDecorations: hasDecorations), lineWidth: 1.2)
            }
            .overlay {
                if isAddHinted {
                    TabBarAddHint(shape: Circle())
                }
            }
            .animation(.easeOut(duration: 0.3), value: isAddHinted)
            .contentShape(Circle())
        }
        .buttonStyle(PressStyle())
        .glass(tint: Palette.backgroundBottom.opacity(.strong), in: Circle())
        .glow(Palette.glow.opacity(.muted), radius: 14, y: 4)
        .haptic(.impact(weight: .light), trigger: addCount)
    }

    func tabItem(
        _ item: Item,
        isHighlighted: Bool
    ) -> some View {
        let iconColor = isHighlighted ? Palette.accent : Palette.subtext
        let titleColor = isHighlighted ? Palette.accentStrong : Palette.subtext

        let iconScale: Image.Scale = showsTitles ? .medium : .large

        return VStack(spacing: 4) {
            Image(systemName: item.systemImage)
                .sansFont(.headline, weight: .light)
                .imageScale(iconScale)
                .foregroundStyle(iconColor)

            if showsTitles {
                Text(item.title)
                    .textFont(size: .caption)
                    .tracking(0.6)
                    .foregroundStyle(titleColor)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.height - 12)
        .contentShape(Capsule())
    }
}

private extension FloatingTabBar {
    static var bottomGap: CGFloat {
        4
    }

    var itemWidth: CGFloat {
        items.isEmpty ? 0 : barWidth / CGFloat(items.count)
    }

    var selectedIndex: Int? {
        items.firstIndex { $0.value == selection }
    }

    var highlightedIndex: Int? {
        dragX.map(index(at:)) ?? selectedIndex
    }

    var indicatorX: CGFloat {
        guard let dragX else {
            return itemWidth * CGFloat(selectedIndex ?? 0)
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

                selection = items[index].value

                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    dragX = nil
                }
            }
    }

    func index(at x: CGFloat) -> Int {
        guard itemWidth > 0 else {
            return selectedIndex ?? 0
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
            items: items,
            isAddHinted: true
        ) {}
    }
    .background(Palette.background)
}
