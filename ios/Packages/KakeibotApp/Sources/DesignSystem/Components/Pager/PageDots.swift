import SwiftUI

public struct PageDots: View {
    let count: Int
    let current: Int

    public init(
        count: Int,
        current: Int
    ) {
        self.count = count
        self.current = current
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Palette.gold : Palette.line)
                    .frame(width: index == current ? 16 : 6, height: 6)
            }
        }
        .animation(.easeOut(duration: 0.2), value: current)
        .opacity(count > 1 ? 1 : 0)
    }
}

#Preview {
    VStack(spacing: 16) {
        PageDots(count: 2, current: 0)
        PageDots(count: 3, current: 2)
    }
    .padding()
    .background(Palette.night)
}
