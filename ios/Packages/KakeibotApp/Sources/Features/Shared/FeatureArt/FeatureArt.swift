import Core
import DesignSystem
import SwiftUI

struct FeatureArt: View {
    @Environment(\.themeStyle.corner) private var corner

    let kind: Kind

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.faint, in: .rect(cornerRadius: corner.radius(16)))
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(16))
                    .stroke(Palette.hairline, lineWidth: 1)
            }
    }
}

extension FeatureArt {
    enum Kind: Hashable, Sendable {
        case receipt
        case items
        case carryover
        case sync
        case share
        case theme
        case fonts
    }
}

private extension FeatureArt {
    @ViewBuilder
    var content: some View {
        switch kind {
        case .receipt: receipt
        case .items: items
        case .carryover: carryover
        case .sync: sync
        case .share: share
        case .theme: theme
        case .fonts: fonts
        }
    }
}
