import Core
import DesignSystem
import SwiftUI

public struct LaunchScreenView: View {
    @State private var model: LaunchScreenModel

    public init(model: LaunchScreenModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("起動時に開く画面")

            ScrollView {
                VStack(spacing: 12) {
                    SettingsIntroCard(
                        systemImage: "iphone",
                        headline: ("アプリを開いたときに", "最初に出す画面を選べます")
                    )

                    LaunchScreenPreview(selection: model.screen)
                        .padding(.vertical, 16)

                    ForEach(LaunchScreen.allCases, id: \.self) { screen in
                        SettingsOption(
                            screen.title,
                            note: screen.note,
                            systemImage: screen.systemImage,
                            isSelected: model.screen == screen
                        ) {
                            Task {
                                await model.choose(screen)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .haptic(.selection, trigger: model.screen)
        .task {
            await model.load()
        }
    }
}
