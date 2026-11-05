import DesignSystem
import SwiftUI

struct RecordsFilterClearButton: View {
    var count: Int?

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "xmark")
                    .sansFont(.small, weight: .semibold)

                Text(title)
                    .textFont(.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 8)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension RecordsFilterClearButton {
    var title: String {
        guard let count else {
            return "絞り込みを外す"
        }

        return "絞り込みを外す(\(count))"
    }
}

#Preview {
    VStack(spacing: 16) {
        RecordsFilterClearButton {}
        RecordsFilterClearButton(count: 3) {}
    }
    .padding()
    .background(Palette.background)
}
