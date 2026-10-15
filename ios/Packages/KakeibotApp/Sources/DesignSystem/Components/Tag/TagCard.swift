import SwiftUI

public struct TagCard: View {
    let title: String
    let style: Style
    let size: Size

    public init(
        _ title: String,
        style: Style = .plain,
        size: Size = .regular
    ) {
        self.title = title
        self.style = style
        self.size = size
    }

    public var body: some View {
        Text(title)
            .font(.system(size: size.fontSize))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .fixedSize()
            .padding(.top, size.holeSpace)
            .padding(.horizontal, size.padding)
            .frame(minWidth: size.minWidth, minHeight: size.height)
            .background(fill, in: shape)
            .overlay {
                shape
                    .stroke(stroke, style: strokeStyle)
            }
            .overlay(alignment: .top) {
                Circle()
                    .stroke(stroke, lineWidth: 0.8)
                    .frame(width: size.hole, height: size.hole)
                    .padding(.top, size.holeTop)
            }
    }
}

public extension TagCard {
    enum Style: Hashable, Sendable {
        case plain
        case selected
        case add
    }

    enum Size: Hashable, Sendable {
        case regular
        case small
    }
}

private extension TagCard {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size.radius)
    }

    var foreground: Color {
        switch style {
        case .plain: Palette.mist
        case .selected: Palette.champagne
        case .add: Palette.gold
        }
    }

    var fill: Color {
        switch style {
        case .plain: Palette.drawer
        case .selected: Palette.gold.opacity(0.16)
        case .add: Color.clear
        }
    }

    var stroke: Color {
        switch style {
        case .plain: Palette.gold.opacity(0.4)
        case .selected: Palette.gold
        case .add: Palette.gold.opacity(0.5)
        }
    }

    var strokeStyle: StrokeStyle {
        style == .add
            ? StrokeStyle(lineWidth: 1, dash: [3, 2])
            : StrokeStyle(lineWidth: 1)
    }
}

private extension TagCard.Size {
    var fontSize: CGFloat {
        switch self {
        case .regular: 11
        case .small: 9
        }
    }

    var height: CGFloat {
        switch self {
        case .regular: 30
        case .small: 18
        }
    }

    var minWidth: CGFloat {
        switch self {
        case .regular: 56
        case .small: 0
        }
    }

    var padding: CGFloat {
        switch self {
        case .regular: 8
        case .small: 6
        }
    }

    var radius: CGFloat {
        switch self {
        case .regular: 4
        case .small: 3
        }
    }

    var hole: CGFloat {
        switch self {
        case .regular: 4
        case .small: 3
        }
    }

    var holeTop: CGFloat {
        switch self {
        case .regular: 3
        case .small: 2
        }
    }

    var holeSpace: CGFloat {
        switch self {
        case .regular: 5
        case .small: 6
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        TagCard("朝ごはん")
        TagCard("昼ごはん", style: .selected)
        TagCard("＋", style: .add)
        TagCard("夜ごはん", size: .small)
    }
    .padding()
    .background(Palette.night)
}
