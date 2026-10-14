import SwiftUI

public struct FloatingTabBar<Value: Hashable>: View {
    @Binding var selection: Value

    @Namespace private var namespace

    let items: [Item]
    let addTitle: String
    let onAdd: () -> Void

    public init(
        selection: Binding<Value>,
        items: [Item],
        addTitle: String,
        onAdd: @escaping () -> Void
    ) {
        _selection = selection
        self.items = items
        self.addTitle = addTitle
        self.onAdd = onAdd
    }

    public var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(items, id: \.value) { item in
                    tabButton(item)
                }
            }
            .padding(6)
            .glass(tint: nil, in: Capsule())

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: Self.height, height: Self.height)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glass(tint: Palette.gold.opacity(0.55), in: Circle())
            .accessibilityLabel(addTitle)
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
    func tabButton(_ item: Item) -> some View {
        let isSelected = item.value == selection

        return Button {
            withAnimation(.snappy) {
                selection = item.value
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 19, weight: .light))

                Text(item.title)
                    .font(.system(size: 10))
            }
            .foregroundStyle(isSelected ? Palette.champagne : Palette.mist)
            .frame(maxWidth: .infinity, minHeight: Self.height - 12)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Palette.gold.opacity(0.16))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension View {
    @ViewBuilder
    func glass(
        tint: Color?,
        in shape: some Shape
    ) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular.tint(tint).interactive(), in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.stroke(.white.opacity(0.12), lineWidth: 1)
                }
        }
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
            addTitle: "記録する"
        ) {}
    }
    .background(Palette.night)
}
