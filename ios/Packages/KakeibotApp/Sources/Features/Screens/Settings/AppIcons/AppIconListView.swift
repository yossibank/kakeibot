import DesignSystem
import FeatureModels
import Store
import SwiftUI

public struct AppIconListView: View {
    @Bindable private var model: AppIconListModel

    @State private var hintFlag: SettingsScreenFlag

    public init(
        model: AppIconListModel,
        parts: ScreenParts
    ) {
        let hintFlag = SettingsScreenFlag.closedHint(.appIcons, in: parts)

        self.model = model
        _hintFlag = State(initialValue: hintFlag)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("アプリアイコン", hint: hintFlag)

            SettingsIntroCard(
                systemImage: "app.badge",
                headline: ("ホーム画面のアイコンを", "好きな色にできます"),
                notes: [
                    .init("arrow.triangle.2.circlepath", "押すと、すぐに切り替わります"),
                    .init("circle.lefthalf.filled", "ライト用とダーク用から選べます")
                ],
                flag: hintFlag
            )

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    section("ライト", isLight: true)
                    section("ダーク", isLight: false)
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .settingsScreen(errorNotice: Bindable(model.state).errorNotice)
        .haptic(.selection, trigger: model.input.current)
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
                        isCurrent: choice == model.input.current,
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
