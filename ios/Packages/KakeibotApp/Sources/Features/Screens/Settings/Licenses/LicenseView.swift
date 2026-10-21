import DesignSystem
import SwiftUI

struct LicenseView: View {
    let license: License

    var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader(license.title)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let source = license.source {
                        Link(destination: source) {
                            Label(
                                "配布元を開く",
                                systemImage: "arrow.up.right.square"
                            )
                            .textFont(.footnote)
                            .foregroundStyle(Palette.accent)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .card()
                        }
                    }

                    Text(license.text)
                        .textFont(.caption)
                        .foregroundStyle(Palette.text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .card()
                }
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
