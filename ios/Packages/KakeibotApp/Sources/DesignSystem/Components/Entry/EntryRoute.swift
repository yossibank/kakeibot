import SwiftUI

public struct EntryRoute: View {
    let source: String
    let destination: String

    public init(
        source: String,
        destination: String
    ) {
        self.source = source
        self.destination = destination
    }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .strokeBorder(Palette.subtext, lineWidth: 1)
                .frame(width: 7, height: 7)

            Text(source)
                .foregroundStyle(Palette.subtext)
                .sharedTextScale()

            Capsule()
                .fill(Palette.outline)
                .frame(width: 20, height: 1)

            Circle()
                .fill(Palette.accent)
                .frame(width: 7, height: 7)

            Text(destination)
                .foregroundStyle(Palette.accentStrong)
                .sharedTextScale()
        }
        .textFont(.caption)
    }
}

#Preview {
    EntryRoute(source: "みずほ銀行", destination: "財布")
        .padding()
}
