import SwiftUI

public struct SwipeRow<ID: Hashable, Content: View>: View {
    @Binding private var openId: ID?

    @State private var offset: CGFloat = 0
    @State private var width: CGFloat = 0

    private let id: ID
    private let onTap: () -> Void
    private let onDelete: () -> Void
    private let content: Content

    public init(
        id: ID,
        openId: Binding<ID?>,
        onTap: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        _openId = openId
        self.id = id
        self.onTap = onTap
        self.onDelete = onDelete
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            deleteButton

            content
                .contentShape(.rect)
                .onTapGesture {
                    tap()
                }
                .gesture(
                    SwipeGesture { x in
                        move(by: x)
                    } onEnd: { _ in
                        end()
                    }
                )
                .offset(x: offset)
        }
        .clipped()
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            self.width = width
        }
        .onChange(of: openId) { _, newId in
            guard newId != id, offset != 0 else {
                return
            }

            withAnimation(.snappy) {
                offset = 0
            }
        }
        .sensoryFeedback(
            .impact(weight: .medium),
            trigger: isPastDelete
        ) { _, isPast in
            isPast
        }
    }
}

private extension SwipeRow {
    var deleteButton: some View {
        let buttonWidth = max(-offset, Self.actionWidth) - Self.gap
        let opacity = min(-offset / Self.actionWidth, 1)

        return Button(action: onDelete) {
            VStack(spacing: 3) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .medium))

                Text("削除")
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
            }
            .foregroundStyle(Palette.cardBottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Self.fill, in: Self.shape)
            .overlay {
                Self.shape
                    .fill(Self.sheen)
            }
            .contentShape(Self.shape)
        }
        .buttonStyle(.plain)
        .frame(width: buttonWidth)
        .padding(.vertical, 6)
        .opacity(opacity)
    }
}

private extension SwipeRow {
    static var actionWidth: CGFloat {
        76
    }

    static var gap: CGFloat {
        8
    }

    static var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 14)
    }

    static var fill: LinearGradient {
        LinearGradient(
            colors: [Palette.rose, Palette.rose.opacity(0.78)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var sheen: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.18), .white.opacity(0)],
            startPoint: .top,
            endPoint: .center
        )
    }

    var isOpen: Bool {
        openId == id
    }

    var isPastDelete: Bool {
        width > 0 && -offset > width * 0.6
    }

    func tap() {
        guard openId == nil else {
            openId = nil
            return
        }

        onTap()
    }

    func move(by x: CGFloat) {
        if openId != nil, !isOpen {
            openId = nil
        }

        let start = isOpen ? -Self.actionWidth : 0
        offset = min(start + x, 0)
    }

    func end() {
        if isPastDelete {
            withAnimation(.snappy) {
                offset = -width
            }

            onDelete()
            return
        }

        let opens = -offset > Self.actionWidth / 2

        withAnimation(.snappy) {
            offset = opens ? -Self.actionWidth : 0
        }

        if opens {
            openId = id
        } else if isOpen {
            openId = nil
        }
    }
}
