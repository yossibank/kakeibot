import SwiftUI

public struct SelectionMark: View {
    private let isSelected: Bool

    public init(isSelected: Bool) {
        self.isSelected = isSelected
    }

    public var body: some View {
        Image(systemName: systemImage)
            .sansFont(.headline)
            .foregroundStyle(Palette.accent)
            .contentTransition(.symbolEffect(.replace))
    }
}

private extension SelectionMark {
    var systemImage: String {
        isSelected ? "checkmark.circle.fill" : "circle"
    }
}

#Preview {
    HStack(spacing: 16) {
        SelectionMark(isSelected: true)
        SelectionMark(isSelected: false)
    }
    .padding()
    .background(Palette.background)
}
