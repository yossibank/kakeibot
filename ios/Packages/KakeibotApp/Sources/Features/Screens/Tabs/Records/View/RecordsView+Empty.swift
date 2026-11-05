import DesignSystem
import SwiftUI

extension RecordsView {
    var filteredEmpty: some View {
        PlaceholderEmpty(
            systemImage: "line.3.horizontal.decrease",
            text: "絞り込みに合う記録はありません"
        ) {
            RecordsFilterClearButton {
                clearFilter()
            }
        }
    }

    func clearFilter() {
        withAnimation(.snappy) {
            model.clearFilter()
        }
    }
}
