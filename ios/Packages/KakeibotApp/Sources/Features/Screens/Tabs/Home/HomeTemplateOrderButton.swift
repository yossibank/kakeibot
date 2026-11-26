import DesignSystem
import SwiftUI

struct HomeTemplateOrderButton: View {
    @State private var layout = Layout()

    let title: String
    let onOpen: (CGRect) -> Void

    var body: some View {
        Button {
            onOpen(layout.frame)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .sansFont(.caption, weight: .light)

                Text(title)
                    .textFont(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .overlay {
                Capsule()
                    .stroke(Self.stroke, lineWidth: 1)
            }
            .frame(height: 40)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            layout.frame = frame
        }
    }
}

private extension HomeTemplateOrderButton {
    struct Layout {
        var frame: CGRect = .zero
    }
}

private extension HomeTemplateOrderButton {
    static let stroke = Palette.accent.opacity(.muted)
}
