import DesignSystem
import SwiftUI

struct RecordsMarkMenu: View {
    @State private var layout = Layout()

    let anchor: CGRect
    let onStamp: () -> Void
    let onReward: () -> Void
    let onClose: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            let local = anchor.offsetBy(dx: -origin.x, dy: -origin.y)

            ZStack(alignment: .topLeading) {
                Scrim(.menu)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)

                panel
                    .offset(
                        x: panelX(for: local, in: proxy.size.width),
                        y: panelY(for: local, in: proxy.size.height)
                    )
            }
        }
    }
}

private extension RecordsMarkMenu {
    struct Layout {
        var panelHeight: CGFloat = 0
    }

    static let width: CGFloat = 248
    static let inset: CGFloat = 16
    static let gap: CGFloat = 6

    var panel: some View {
        MenuPanel(width: Self.width) {
            MenuHeader("この日に付けるもの") {
                Image(systemName: "plus")
                    .sansFont(.small, weight: .light)
            }

            MenuDivider()

            MenuRow(
                "スタンプを押す",
                note: "その日に印を 1 つ押します",
                systemImage: "seal",
                action: onStamp
            )

            MenuDivider()

            MenuRow(
                "ごほうびを付ける",
                note: "決まりの額を貯金箱に貯めます",
                systemImage: "gift",
                action: onReward
            )
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            layout.panelHeight = height
        }
    }

    func panelX(
        for anchor: CGRect,
        in width: CGFloat
    ) -> CGFloat {
        MenuPlacement.trailingX(
            of: anchor,
            panelWidth: Self.width,
            in: width,
            inset: Self.inset
        )
    }

    func panelY(
        for anchor: CGRect,
        in height: CGFloat
    ) -> CGFloat {
        let below = anchor.maxY + Self.gap
        let above = anchor.minY - Self.gap - layout.panelHeight

        guard below + layout.panelHeight > height, above >= 0 else {
            return below
        }

        return above
    }
}

#Preview {
    RecordsMarkMenu(
        anchor: CGRect(x: 330, y: 220, width: 26, height: 26),
        onStamp: {},
        onReward: {},
        onClose: {}
    )
    .background(Palette.background)
}
