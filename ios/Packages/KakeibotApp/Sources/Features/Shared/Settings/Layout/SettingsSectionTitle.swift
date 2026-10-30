import DesignSystem
import SwiftUI

struct SettingsSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        SectionTitle(title)
            .padding(.leading, 8)
    }
}
