import SwiftUI
import UIKit

public struct CapsulePicker<Value: Hashable>: View {
    @Binding var selection: Value

    @State private var thumbOffset: CGFloat?
    @State private var feedback = UISelectionFeedbackGenerator()

    let options: [Option]

    public init(
        selection: Binding<Value>,
        options: [Option]
    ) {
        _selection = selection
        self.options = options
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Self.thumbFill)
                .overlay {
                    Capsule()
                        .strokeBorder(Self.thumbRim, lineWidth: 0.8)
                }
                .shadow(color: Palette.glow.opacity(.muted), radius: 6)
                .frame(width: Self.segmentWidth, height: Self.segmentHeight)
                .offset(x: thumbX)

            HStack(spacing: 0) {
                ForEach(
                    Array(options.enumerated()),
                    id: \.offset
                ) { index, option in
                    let isHighlighted = index == highlightedIndex
                    let weight: Font.Weight = isHighlighted ? .bold : .regular
                    let color = isHighlighted
                        ? Palette.accentStrong
                        : Palette.subtext

                    Text(option.title)
                        .textFont(.footnote, weight: weight)
                        .foregroundStyle(color)
                        .frame(
                            width: Self.segmentWidth,
                            height: Self.segmentHeight
                        )
                }
            }
        }
        .padding(Self.inset)
        .fixedSize()
        .background {
            Capsule()
                .fill(Self.sheen)
        }
        .overlay {
            Capsule()
                .strokeBorder(Self.rim, lineWidth: 1)
        }
        .glass(tint: Palette.backgroundBottom.opacity(.medium), in: Capsule())
        .contentShape(Capsule())
        .gesture(dragGesture)
        .onAppear {
            feedback.prepare()
        }
        .onChange(of: highlightedIndex) {
            feedback.selectionChanged()
            feedback.prepare()
        }
    }
}

public extension CapsulePicker {
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
    static var segmentWidth: CGFloat {
        72
    }

    static var segmentHeight: CGFloat {
        30
    }

    static var inset: CGFloat {
        3
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

    var selectedIndex: Int {
        options.firstIndex { $0.value == selection } ?? 0
    }

    var maxOffset: CGFloat {
        CGFloat(options.count - 1) * Self.segmentWidth
    }

    var thumbX: CGFloat {
        thumbOffset ?? CGFloat(selectedIndex) * Self.segmentWidth
    }

    var highlightedIndex: Int {
        index(at: thumbX + Self.segmentWidth / 2)
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                feedback.prepare()
                let start = CGFloat(selectedIndex) * Self.segmentWidth
                let touch = value.startLocation.x - Self.inset

                let range = start...(start + Self.segmentWidth)

                guard range.contains(touch) else {
                    return
                }

                let offset = start + value.translation.width
                thumbOffset = min(max(offset, 0), maxOffset)
            }
            .onEnded { value in
                let center = thumbOffset.map { $0 + Self.segmentWidth / 2 }
                let index = index(at: center ?? value.location.x - Self.inset)

                withAnimation(Self.spring) {
                    thumbOffset = nil
                    selection = options[index].value
                }
            }
    }

    func index(at x: CGFloat) -> Int {
        let index = Int((x / Self.segmentWidth).rounded(.down))
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
