import Core
import SwiftUI

public struct AddTile: View {
    @Environment(\.themeStyle.corner) private var corner

    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))

        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .sansFont(.headline, weight: .ultraLight)

                Text("追加")
                    .textFont(.caption2)
            }
            .foregroundStyle(Palette.accent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.faint, in: shape)
            .overlay {
                shape
                    .stroke(Palette.outline, style: .dashed)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddTile {}
        .frame(width: 80, height: 78)
        .padding()
        .background(Palette.background)
}
