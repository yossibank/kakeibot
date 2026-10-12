import SwiftUI

public struct PrimaryButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let action: () -> Void

    public init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(isEnabled ? Palette.nightBottom : Palette.mist)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(isEnabled ? Palette.gold : Palette.line, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("¥12,800 を記録する") {}

        PrimaryButton("金額を入れてください") {}
            .disabled(true)
    }
    .padding()
    .background(Palette.night)
}
