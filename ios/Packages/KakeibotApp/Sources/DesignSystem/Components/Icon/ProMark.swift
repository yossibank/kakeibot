import SwiftUI

public struct ProMark: View {
    public init() {}

    public var body: some View {
        Image(systemName: "sparkles")
            .sansFont(.caption, weight: .semibold)
            .foregroundStyle(Palette.accent)
    }
}

#Preview {
    ProMark()
        .padding()
        .background(Palette.background)
}
