import SwiftUI

public struct SideTabBar<Value: Hashable>: View {
    @Binding var selection: Value

    @Environment(\.themeStyle.decorations) private var hasDecorations

    let title: String
    let items: [FloatingTabBar<Value>.Item]
    let isAddHinted: Bool
    let onAdd: () -> Void

    public init(
        selection: Binding<Value>,
        title: String,
        items: [FloatingTabBar<Value>.Item],
        isAddHinted: Bool = false,
        onAdd: @escaping () -> Void
    ) {
        _selection = selection

        self.title = title
        self.items = items
        self.isAddHinted = isAddHinted
        self.onAdd = onAdd
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .displayFont(.headline)
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)

            VStack(spacing: 4) {
                ForEach(items, id: \.value) { item in
                    tabItem(item)
                }
            }

            Spacer()

            addButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(width: Self.width)
        .frame(maxHeight: .infinity)
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Palette.hairline)
                .frame(width: 0.5)
                .ignoresSafeArea()
        }
        .haptic(.selection, trigger: selection)
    }
}

public extension SideTabBar {
    static var width: CGFloat {
        240
    }
}

private extension SideTabBar {
    var addButton: some View {
        Button(action: onAdd) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .sansFont(.headline, weight: .ultraLight)

                Text("記録する")
                    .textFont(size: .body, weight: .medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Palette.accentStrong)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                Capsule()
                    .fill(TabBarStyle.sheen)
            }
            .overlay {
                Capsule()
                    .strokeBorder(TabBarStyle.ring(hasDecorations: hasDecorations), lineWidth: 1.2)
            }
            .overlay {
                if isAddHinted {
                    TabBarAddHint(shape: Capsule())
                }
            }
            .animation(.easeOut(duration: 0.3), value: isAddHinted)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glass(tint: Palette.backgroundBottom.opacity(.strong), in: Capsule())
        .glow(Palette.glow.opacity(.muted), radius: 14, y: 4)
    }

    func tabItem(_ item: FloatingTabBar<Value>.Item) -> some View {
        let isSelected = item.value == selection
        let iconColor = isSelected ? Palette.accent : Palette.subtext
        let titleColor = isSelected ? Palette.accentStrong : Palette.text
        let fill = isSelected ? Palette.accent.opacity(.subtle) : .clear
        let rimOpacity: Double = isSelected ? 1 : 0

        return Button {
            withAnimation(.snappy(duration: 0.25)) {
                selection = item.value
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.systemImage)
                    .sansFont(.headline, weight: .light)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)

                Text(item.title)
                    .textFont(size: .body)
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background {
                Capsule()
                    .fill(fill)
                    .overlay {
                        Capsule()
                            .strokeBorder(TabBarStyle.indicatorRim, lineWidth: 0.8)
                            .opacity(rimOpacity)
                    }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
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

    HStack(spacing: 0) {
        SideTabBar(
            selection: $selection,
            title: "かけいぼっと",
            items: items,
            isAddHinted: true
        ) {}

        Spacer()
    }
    .background(Palette.background)
}
