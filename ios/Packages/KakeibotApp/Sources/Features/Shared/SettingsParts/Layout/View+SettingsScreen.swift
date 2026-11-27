import DesignSystem
import FeatureModels
import SwiftUI

extension View {
    func settingsScreen(errorNotice: ErrorNotice) -> some View {
        padding(.horizontal, SettingsSpacing.side)
            .padding(.top, SettingsSpacing.top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .errorBanner(errorNotice)
            .backdrop()
            .toolbar(.hidden, for: .navigationBar)
    }
}
