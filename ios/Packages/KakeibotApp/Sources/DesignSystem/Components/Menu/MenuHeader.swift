import SwiftUI

public struct MenuHeader<Leading: View>: View {
    let title: String
    let leading: Leading

    public init(
        _ title: String,
        @ViewBuilder leading: () -> Leading
    ) {
        self.title = title
        self.leading = leading()
    }

    public var body: some View {
        HStack(spacing: 10) {
            leading
                .foregroundStyle(Palette.accent)

            Text(title)
                .font(.serif(.small))
                .tracking(1)
                .foregroundStyle(Palette.accentLight)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}
