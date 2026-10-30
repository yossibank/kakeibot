import SwiftUI

public struct CapsulePicker<Value: Hashable>: View {
    @Binding var selection: Value

    @State private var thumbOffset: CGFloat?
    @State private var pendingIndex: Int?
    @State private var width: CGFloat?

    @Environment(\.themeStyle.textSize.scale) private var textScale

    let options: [Option]
    let size: Size

    public init(
        selection: Binding<Value>,
        options: [Option],
        size: Size = .regular
    ) {
        _selection = selection

        self.options = options
        self.size = size
    }

    public var body: some View {
        let indexedOptions = Array(options.enumerated())

        ZStack(alignment: .leading) {
            Capsule()
                .fill(Self.thumbFill)
                .overlay {
                    Capsule()
                        .strokeBorder(Self.thumbRim, lineWidth: 0.8)
                }
                .glow(Palette.glow.opacity(.muted), radius: 6)
                .frame(width: segmentWidth, height: segmentHeight)
                .offset(x: thumbX)

            HStack(spacing: 0) {
                ForEach(indexedOptions, id: \.offset) { index, option in
                    let isHighlighted = index == highlightedIndex
                    let weight: Font.Weight = isHighlighted ? .bold : .regular
                    let color = isHighlighted ? Palette.accentStrong : Palette.subtext

                    Text(option.title)
                        .textFont(size.font, weight: weight)
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: segmentWidth, height: segmentHeight)
                }
            }
        }
        .padding(Self.inset)
        .frame(minWidth: 0, maxWidth: idealWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            self.width = width
        }
        .background {
            Capsule()
                .fill(Self.sheen)
        }
        .overlay {
            Capsule()
                .strokeBorder(Self.rim, lineWidth: 1)
        }
        .glass(tint: Palette.backgroundBottom.opacity(.medium), in: Capsule())
        .tapArea(tapOutsets)
        .gesture(dragGesture)
        .haptic(.selection, trigger: highlightedIndex)
        .onChange(of: selection) {
            pendingIndex = nil
        }
    }
}

public extension CapsulePicker {
    enum Size: Sendable {
        case regular
        case small

        var font: Font.TextStyle {
            switch self {
            case .regular: .footnote
            case .small: .caption
            }
        }

        var segment: CGSize {
            switch self {
            case .regular: CGSize(width: 72, height: 30)
            case .small: CGSize(width: 56, height: 26)
            }
        }
    }

    struct Option {
        public let title: String
        public let value: Value

        public init(
            _ title: String,
            value: Value
        ) {
            self.title = title
            self.value = value
        }
    }
}

private extension CapsulePicker {
    static var inset: CGFloat {
        4
    }

    static var minimumTapHeight: CGFloat {
        44
    }

    static var thumbFill: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(.muted),
                Palette.accent.opacity(.soft)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var thumbRim: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accentStrong.opacity(.strong),
                Palette.accent.opacity(.muted)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var sheen: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.06), .white.opacity(0)],
            startPoint: .top,
            endPoint: .center
        )
    }

    static var rim: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(.strong),
                Palette.accent.opacity(.soft)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var spring: Animation {
        .spring(response: 0.32, dampingFraction: 0.78)
    }

    var idealSegmentWidth: CGFloat {
        size.segment.width * textScale
    }

    var idealWidth: CGFloat {
        idealSegmentWidth * CGFloat(options.count) + Self.inset * 2
    }

    var segmentWidth: CGFloat {
        guard
            let width,
            width > Self.inset * 2
        else {
            return idealSegmentWidth
        }

        let fitted = (width - Self.inset * 2) / CGFloat(options.count)

        return min(idealSegmentWidth, fitted)
    }

    var segmentHeight: CGFloat {
        size.segment.height * textScale
    }

    var tapOutsets: EdgeInsets {
        let outset = max(0, (Self.minimumTapHeight - segmentHeight) / 2 - Self.inset)

        return EdgeInsets(
            top: outset,
            leading: 0,
            bottom: outset,
            trailing: 0
        )
    }

    var selectedIndex: Int {
        options.firstIndex { $0.value == selection } ?? 0
    }

    var maxOffset: CGFloat {
        CGFloat(options.count - 1) * segmentWidth
    }

    var shownIndex: Int {
        pendingIndex ?? selectedIndex
    }

    var thumbX: CGFloat {
        thumbOffset ?? CGFloat(shownIndex) * segmentWidth
    }

    var highlightedIndex: Int {
        index(at: thumbX + segmentWidth / 2)
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let start = CGFloat(shownIndex) * segmentWidth
                let touch = value.startLocation.x - Self.inset
                let range = start...(start + segmentWidth)

                guard range.contains(touch) else {
                    return
                }

                let offset = start + value.translation.width

                thumbOffset = min(max(offset, 0), maxOffset)
            }
            .onEnded { value in
                let center = thumbOffset.map { $0 + segmentWidth / 2 }
                let x = center ?? value.location.x - Self.inset
                let index = index(at: x)

                withAnimation(Self.spring) {
                    thumbOffset = nil
                    pendingIndex = index == selectedIndex ? nil : index
                    selection = options[index].value
                }
            }
    }

    func index(at x: CGFloat) -> Int {
        let index = Int((x / segmentWidth).rounded(.down))
        return min(max(index, 0), options.count - 1)
    }
}

#Preview {
    @Previewable @State var selection = 0

    CapsulePicker(
        selection: $selection,
        options: [
            .init("支出", value: 0),
            .init("収入", value: 1)
        ]
    )
    .padding()
    .background(Palette.background)
}
