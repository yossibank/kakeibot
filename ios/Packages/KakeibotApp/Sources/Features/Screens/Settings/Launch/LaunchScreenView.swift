import Core
import DesignSystem
import SwiftUI

public struct LaunchScreenView: View {
    @State private var model: LaunchScreenModel

    public init(model: LaunchScreenModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 18) {
            SettingsBackHeader("起動時に開く画面")

            Text("アプリを開いたときに、最初に出す画面を選べます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 12) {
                    LaunchScreenPreview(selection: model.screen)
                        .padding(.vertical, 12)

                    ForEach(LaunchScreen.allCases, id: \.self) { screen in
                        LaunchScreenOption(
                            screen: screen,
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
        .sensoryFeedback(.selection, trigger: model.screen)
        .task {
            await model.load()
        }
    }
}

private extension LaunchScreenView {}
