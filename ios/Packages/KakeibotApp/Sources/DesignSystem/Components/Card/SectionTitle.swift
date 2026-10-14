import SwiftUI

public struct SectionTitle: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(.system(size: 11))
            .tracking(3)
            .foregroundStyle(Palette.gold)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    SectionTitle("最近の記録")
        .padding()
        .background(Palette.night)
}
