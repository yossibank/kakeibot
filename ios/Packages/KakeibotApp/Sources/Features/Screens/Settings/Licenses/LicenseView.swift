import DesignSystem
import SwiftUI

struct LicenseView: View {
    let license: License

    var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader(license.title)

            ScrollView {
                Text(license.text)
                    .textFont(.caption)
                    .foregroundStyle(Palette.text)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .card()
                    .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
