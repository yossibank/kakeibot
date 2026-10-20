import SwiftUI

public struct SwipeRow<ID: Hashable, Content: View>: View {
    @Environment(\.themeStyle.corner) private var corner

    @Binding private var openId: ID?

    @State private var offset: CGFloat = 0
    @State private var width: CGFloat = 0

    private let id: ID
    private let role: Role
    private let onTap: () -> Void
    private let onAction: () -> Void
    private let content: Content

    public init(
        id: ID,
        openId: Binding<ID?>,
        role: Role = .delete,
        onTap: @escaping () -> Void,
        onAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        _openId = openId
        self.id = id
        self.role = role
        self.onTap = onTap
        self.onAction = onAction
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            actionButton

            content
                .contentShape(.rect)
                .onTapGesture {
                    tap()
                }
                .gesture(
                    SwipeGesture(allowsRightward: isOpen) { x in
                        move(by: x)
                    } onEnd: { _ in
                        end()
                    }
                )
                .offset(x: offset)
        }
        .mask {
            Rectangle()
                .padding(.leading, offset == 0 ? -Self.shadowRoom : 0)
                .padding([.vertical, .trailing], -Self.shadowRoom)
        }
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
            trigger: isPastAction
        ) { _, isPast in
            isPast
        }
    }
}

public extension SwipeRow {
    enum Role: Sendable {
        case delete
        case hide
    }
}

private extension SwipeRow {
    var actionButton: some View {
        let buttonWidth = max(-offset, Self.actionWidth) - Self.gap
        let opacity = min(-offset / Self.actionWidth, 1)

        return Button {
            act()
        } label: {
            Image(systemName: systemImage)
                .font(.sans(.body, weight: .medium))
                .foregroundStyle(Palette.cardBottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(fill, in: shape)
                .overlay {
                    shape
                        .fill(Self.sheen)
                }
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .frame(width: buttonWidth)
        .padding(.vertical, 6)
        .opacity(opacity)
    }
}

private extension SwipeRow {
    static var shadowRoom: CGFloat {
        32
    }

    static var actionWidth: CGFloat {
        64
    }

    static var gap: CGFloat {
        8
    }

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(14))
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

    var isPastAction: Bool {
        width > 0 && -offset > width * 0.6
    }

    var systemImage: String {
        switch role {
        case .delete: "trash"
        case .hide: "eye.slash"
        }
    }

    var fill: LinearGradient {
        let color = switch role {
        case .delete: Palette.rose
        case .hide: Palette.accent
        }

        return LinearGradient(
            colors: [color, color.opacity(0.78)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func act() {
        onAction()

        if role == .hide {
            openId = nil
        }
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
        if isPastAction {
            let end: CGFloat = role == .delete ? -width : 0

            withAnimation(.snappy) {
                offset = end
            }

            act()
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
