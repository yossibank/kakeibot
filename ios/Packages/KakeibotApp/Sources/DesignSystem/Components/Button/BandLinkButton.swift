import SwiftUI

public struct BandLinkButton: View {
    private let title: String
    private let action: () -> Void

    public init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .textFont(.footnote, weight: .bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                DisclosureMark(.band)
            }
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Palette.accent.opacity(.faint), in: .rect(cornerRadius: 16))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BandLinkButton("食費をくわしく見る") {}
        .padding()
        .background(Palette.background)
}
