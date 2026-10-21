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
    private let onDelete: (() -> Void)?
    private let content: Content

    public init(
        id: ID,
        openId: Binding<ID?>,
        role: Role = .delete,
        onTap: @escaping () -> Void,
        onAction: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        _openId = openId
        self.id = id
        self.role = role
        self.onTap = onTap
        self.onAction = onAction
        self.onDelete = onDelete
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                if onDelete != nil {
                    deleteButton
                }

                actionButton
            }

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
        let reach = -offset - deleteWidth
        let buttonWidth = max(reach, Self.actionWidth) - Self.gap

        return Button {
            act()
        } label: {
            actionLabel(systemImage, fill: fill)
        }
        .buttonStyle(.plain)
        .frame(width: buttonWidth)
        .padding(.vertical, 6)
        .opacity(opacity)
    }

    var deleteButton: some View {
        Button {
            delete()
        } label: {
            actionLabel("trash", fill: Self.gradient(Palette.rose))
        }
        .buttonStyle(.plain)
        .frame(width: Self.actionWidth - Self.gap)
        .padding(.trailing, Self.gap)
        .padding(.vertical, 6)
        .opacity(opacity)
    }

    func actionLabel(
        _ systemImage: String,
        fill: LinearGradient
    ) -> some View {
        Image(systemName: systemImage)
            .sansFont(.body, weight: .medium)
            .foregroundStyle(Palette.cardBottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(fill, in: shape)
            .overlay {
                shape
                    .fill(Self.sheen)
            }
            .contentShape(shape)
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

    var deleteWidth: CGFloat {
        onDelete == nil ? 0 : Self.actionWidth
    }

    var openWidth: CGFloat {
        Self.actionWidth + deleteWidth
    }

    var opacity: Double {
        min(-offset / openWidth, 1)
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
        switch role {
        case .delete: Self.gradient(Palette.rose)
        case .hide: Self.gradient(Palette.accent)
        }
    }

    static func gradient(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.78)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func delete() {
        openId = nil
        onDelete?()
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

        let start = isOpen ? -openWidth : 0
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

        let opens = -offset > openWidth / 2

        withAnimation(.snappy) {
            offset = opens ? -openWidth : 0
        }

        if opens {
            openId = id
        } else if isOpen {
            openId = nil
        }
    }
}
