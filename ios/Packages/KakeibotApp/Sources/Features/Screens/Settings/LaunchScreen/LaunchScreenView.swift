import Core
import DesignSystem
import SwiftUI

public struct LaunchScreenView: View {
    @State private var model: LaunchScreenModel
    @State private var hintFlag: SettingsScreenFlag

    public init(model: LaunchScreenModel) {
        let hintFlag = model.hintFlag()

        _model = State(initialValue: model)
        _hintFlag = State(initialValue: hintFlag)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("起動時に開く画面", hint: hintFlag)

            SettingsIntroCard(
                systemImage: "iphone",
                headline: ("アプリを開いたときに", "最初に出す画面を選べます"),
                notes: [
                    .init("power", "立ち上げたときに、選んだ画面から始まります"),
                    .init("arrow.uturn.backward", "途中から戻ったときは、前の画面のままです")
                ],
                flag: hintFlag
            )

            ScrollView {
                VStack(spacing: SettingsSpacing.section) {
                    LaunchScreenPreview(selection: model.screen)

                    VStack(spacing: 12) {
                        ForEach(LaunchScreen.allCases, id: \.self) { screen in
                            LaunchScreenOption(
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
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .settingsScreen(errorNotice: $model.errorNotice)
        .haptic(.selection, trigger: model.screen)
        .task {
            await model.load()
        }
    }
}
