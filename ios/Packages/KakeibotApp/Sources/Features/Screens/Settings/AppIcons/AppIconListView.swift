import DesignSystem
import SwiftUI

public struct AppIconListView: View {
    @Bindable private var model: AppIconListModel

    public init(model: AppIconListModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader("アプリアイコン")

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    section("ダーク", isLight: false)

                    section("ライト", isLight: true)
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: model.current)
    }
}

private extension AppIconListView {
    func section(
        _ title: String,
        isLight: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .textFont(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.accent)
                .padding(.leading, 6)

            LazyVGrid(columns: Self.columns, spacing: 18) {
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
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    func choices(isLight: Bool) -> [AppIconChoice] {
        AppIconChoice.allCases.filter { $0.isLight == isLight }
    }
}
