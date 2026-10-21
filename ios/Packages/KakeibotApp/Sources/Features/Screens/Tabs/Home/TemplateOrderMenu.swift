import Core
import DesignSystem
import SwiftUI

public struct TemplateOrderMenu: View {
    @Binding private var selection: TemplateOrder

    private let anchor: CGRect
    private let onClose: () -> Void

    public init(
        selection: Binding<TemplateOrder>,
        anchor: CGRect,
        onClose: @escaping () -> Void
    ) {
        _selection = selection
        self.anchor = anchor
        self.onClose = onClose
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Palette.scrim
                    .opacity(0.45)
                    .onTapGesture(perform: onClose)

                MenuPanel(width: Self.width) {
                    MenuHeader("並べ替え") {
                        Image(systemName: "arrow.up.arrow.down")
                            .sansFont(.small, weight: .light)
                    }

                    ForEach(TemplateOrder.allCases) { order in
                        MenuDivider()

                        MenuRow(
                            order.title,
                            note: order.note,
                            systemImage: order.systemImage,
                            isSelected: order == selection
                        ) {
                            choose(order)
                        }
                    }
                }
                .offset(
                    x: panelX(in: proxy.size.width),
                    y: anchor.maxY + 6
                )
            }
        }
        .ignoresSafeArea()
    }
}

private extension TemplateOrderMenu {
    static let width: CGFloat = 248
    static let inset: CGFloat = 16

    func panelX(in width: CGFloat) -> CGFloat {
        let preferred = anchor.maxX - Self.width
        let limit = width - Self.width - Self.inset
        return min(max(preferred, Self.inset), limit)
    }

    func choose(_ order: TemplateOrder) {
        selection = order
        onClose()
    }
}
