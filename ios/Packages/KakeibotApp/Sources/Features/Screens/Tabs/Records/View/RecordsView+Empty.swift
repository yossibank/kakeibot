import DesignSystem
import SwiftUI

extension RecordsView {
    var filteredEmpty: some View {
        VStack(spacing: 16) {
            Text("絞り込みに合う記録はありません")
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)

            HeaderButton(systemImage: "xmark", title: "絞り込みを外す") {
                clearFilter()
            }
        }
        .padding(.vertical, 40)
    }

    func clearFilter() {
        withAnimation(.snappy) {
            model.clearFilter()
        }
    }
}
