import SwiftUI

public struct Chip: View {
    let title: String
    let systemImage: String

    public init(
        _ title: String,
        systemImage: String
    ) {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .lineLimit(1)
            .foregroundStyle(Palette.ink.opacity(0.85))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
    }
}

#Preview {
    HStack {
        Chip("財布", systemImage: "wallet.bifold")
        Chip("メモ", systemImage: "square.and.pencil")
    }
    .padding()
    .background(Palette.night)
}
