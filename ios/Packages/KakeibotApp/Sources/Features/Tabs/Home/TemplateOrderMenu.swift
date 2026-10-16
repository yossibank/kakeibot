import DesignSystem
import SwiftUI

struct TemplateOrderMenu: View {
    @Binding var selection: TemplateOrder

    let anchor: CGRect
    let onClose: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.black
                    .opacity(0.45)
                    .onTapGesture(perform: onClose)

                MenuPanel(width: Self.width) {
                    MenuHeader("並べ替え") {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 13, weight: .light))
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
