import SwiftUI

public struct SharedMark: View {
    public init() {}

    public var body: some View {
        Image(systemName: "person.2.fill")
            .textFont(.caption2)
            .foregroundStyle(Palette.subtext)
            .fixedSize()
    }
}

#Preview {
    SharedMark()
        .padding()
        .background(Palette.background)
}
