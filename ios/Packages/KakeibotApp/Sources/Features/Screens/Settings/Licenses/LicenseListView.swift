import DesignSystem
import SwiftUI

public struct LicenseListView: View {
    private let licenses: [License]

    public init(licenses: [License] = License.bundled) {
        self.licenses = licenses
    }

    public var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader("ライセンス")

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("このアプリで使っている部品とフォントです")
                        .textFont(.footnote)
                        .foregroundStyle(Palette.subtext)
                        .padding(.leading, 6)

                    VStack(spacing: 0) {
                        ForEach(licenses) { license in
                            NavigationLink {
                                LicenseView(license: license)
                            } label: {
                                row(license)
                            }
                            .overlay(alignment: .top) {
                                if license != licenses.first {
                                    Hairline()
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
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

private extension LicenseListView {
    func row(_ license: License) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(license.title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)

                if let source = license.source {
                    Text(Self.sourceText(source))
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.hint)
        }
        .frame(minHeight: 56)
        .contentShape(.rect)
    }

    static func sourceText(_ url: URL) -> String {
        let host = url.host() ?? ""
        return host + url.path()
    }
}

#Preview {
    NavigationStack {
        LicenseListView(
            licenses: [
                License(
                    id: "a",
                    title: "GRDB.swift (7.11.1)",
                    source: URL(string: "https://github.com/groue/GRDB.swift"),
                    text: "MIT"
                ),
                License(id: "b", title: "Klee One", source: nil, text: "OFL")
            ]
        )
    }
}
