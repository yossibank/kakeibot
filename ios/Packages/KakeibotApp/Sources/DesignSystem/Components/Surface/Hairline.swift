import SwiftUI

public struct Hairline: View {
    private let thickness: CGFloat

    public init(thickness: CGFloat = 0.5) {
        self.thickness = thickness
    }

    public var body: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(height: thickness)
    }
}
