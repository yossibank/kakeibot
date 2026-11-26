import SwiftUI

public struct DisclosureMark: View {
    private let style: Style

    public init(_ style: Style = .row) {
        self.style = style
    }

    public var body: some View {
        switch style {
        case .row:
            image
                .sansFont(.small)
                .foregroundStyle(Palette.hint)

        case .link:
            image
                .sansFont(.micro, weight: .semibold)

        case .strongLink:
            image
                .sansFont(.micro, weight: .bold)

        case .band:
            image
                .sansFont(.small, weight: .bold)
        }
    }
}

public extension DisclosureMark {
    enum Style {
        case row
        case link
        case strongLink
        case band
    }
}

private extension DisclosureMark {
    var image: Image {
        Image(systemName: "chevron.right")
    }
}

#Preview {
    VStack(spacing: 16) {
        DisclosureMark()
        DisclosureMark(.link)
        DisclosureMark(.strongLink)
        DisclosureMark(.band)
    }
    .foregroundStyle(Palette.accent)
    .padding()
    .background(Palette.background)
}
