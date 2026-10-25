import SwiftUI

public struct EditBadge: View {
    @State private var bounce = 0

    private let size: CGFloat
    private let bounces: Bool

    public init(
        size: CGFloat = 18,
        bounces: Bool = false
    ) {
        self.size = size
        self.bounces = bounces
    }

    public var body: some View {
        Image(systemName: "pencil")
            .font(.system(size: size * 0.55, weight: .medium))
            .foregroundStyle(Palette.accent.opacity(.strong))
            .symbolEffect(.bounce, options: .repeat(2), value: bounce)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(Palette.panel)
                    .overlay {
                        Circle()
                            .fill(Palette.accent.opacity(.subtle))
                    }
            }
            .task {
                guard bounces else {
                    return
                }

                try? await Task.sleep(for: .milliseconds(600))

                bounce += 1
            }
    }
}

#Preview {
    HStack(spacing: 16) {
        EditBadge()

        EditBadge(size: 16, bounces: true)

        Text("¥150,000")
            .editBadge()
    }
    .padding()
    .background(Palette.background)
}
