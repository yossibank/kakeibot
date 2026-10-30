import DesignSystem
import SwiftUI

public struct AppIconListView: View {
    @Bindable private var model: AppIconListModel

    public init(model: AppIconListModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("アプリアイコン")

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    SettingsIntroCard(
                        systemImage: "app.badge",
                        headline: ("ホーム画面のアイコンを", "好きな色にできます"),
                        notes: [
                            .init("arrow.triangle.2.circlepath", "押すと、すぐに切り替わります"),
                            .init("circle.lefthalf.filled", "ライト用とダーク用から選べます")
                        ]
                    )

                    section("ライト", isLight: true)

                    section("ダーク", isLight: false)
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, SettingsSpacing.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .haptic(.selection, trigger: model.current)
    }
}

private extension AppIconListView {
    func section(
        _ title: String,
        isLight: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionTitle(title)

            LazyVGrid(columns: Self.columns, spacing: 20) {
                ForEach(choices(isLight: isLight), id: \.self) { choice in
                    AppIconTile(
                        choice: choice,
                        isCurrent: choice == model.current,
                        onSelect: {
                            Task {
                                await model.select(choice)
                            }
                        }
                    )
                }
            }
        }
    }
}

private extension AppIconListView {
    static let columns = Array(
        repeating: GridItem(
            .flexible(),
            spacing: 12
        ),
        count: 3
    )

    func choices(isLight: Bool) -> [AppIconChoice] {
        AppIconChoice.allCases.filter { $0.isLight == isLight }
    }
}
