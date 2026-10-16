import SwiftUI

public struct MenuDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Palette.gold.opacity(0.16))
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }
}
