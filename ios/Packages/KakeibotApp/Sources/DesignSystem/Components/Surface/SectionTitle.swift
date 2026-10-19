import SwiftUI

public struct SectionTitle: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(.sans(.caption))
            .tracking(3)
            .foregroundStyle(Palette.accent)
    }
}

#Preview {
    SectionTitle("最近の記録")
        .padding()
        .background(Palette.background)
}
