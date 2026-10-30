import Core
import SwiftUI

public struct TemplateBadge: View {
    let icon: Icon?
    let size: Size

    public init(
        icon: Icon?,
        size: Size
    ) {
        self.icon = icon
        self.size = size
    }

    public var body: some View {
        IconImage(icon, size: size.iconSize)
            .foregroundStyle(Palette.accent)
            .frame(width: size.diameter, height: size.diameter)
            .background(Palette.faint, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(TemplateCardStyle.foil, lineWidth: 1)
            }
    }
}

public extension TemplateBadge {
    enum Size: Sendable {
        case small
        case regular
        case large
    }
}

public extension TemplateBadge.Size {
    var diameter: CGFloat {
        switch self {
        case .small: 20
        case .regular: 34
        case .large: 52
        }
    }
}

private extension TemplateBadge.Size {
    var iconSize: CGFloat {
        switch self {
        case .small: 11
        case .regular: 16
        case .large: 24
        }
    }
}
