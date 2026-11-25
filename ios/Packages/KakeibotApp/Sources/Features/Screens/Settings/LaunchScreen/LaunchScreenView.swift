import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct LaunchScreenView: View {
    @State private var model: LaunchScreenModel

    public init(model: LaunchScreenModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("起動時に開く画面", hint: hint)

            SettingsIntroCard(
                systemImage: "iphone",
                headline: ("アプリを開いたときに", "最初に出す画面を選べます"),
                notes: [
                    .init("power", "立ち上げたときに、選んだ画面から始まります"),
                    .init("arrow.uturn.backward", "途中から戻ったときは、前の画面のままです")
                ],
                hint: hint
            )

            ScrollView {
                VStack(spacing: SettingsSpacing.section) {
                    LaunchScreenPreview(selection: model.input.screen)

                    VStack(spacing: 12) {
                        ForEach(LaunchScreen.allCases, id: \.self) { screen in
                            LaunchScreenOption(
                                screen.title,
                                note: screen.note,
                                systemImage: screen.systemImage,
                                isSelected: model.input.screen == screen
                            ) {
                                model.perform {
                                    await $0.choose(screen)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .settingsScreen(errorNotice: Bindable(model.state).errorNotice)
        .haptic(.selection, trigger: model.input.screen)
        .task {
            await model.load()
        }
    }
}

private extension LaunchScreenView {
    var hint: SettingsFold {
        SettingsFold(\.hint, in: model)
    }
}
