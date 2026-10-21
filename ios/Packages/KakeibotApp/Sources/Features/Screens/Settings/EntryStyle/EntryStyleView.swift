import Core
import DesignSystem
import SwiftUI

public struct EntryStyleView: View {
    @State private var model: EntryStyleModel

    public init(model: EntryStyleModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 18) {
            SettingsBackHeader("入力シートの見た目")

            Text("記録を入れるシートの見た目を選べます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(EntryStyle.allCases, id: \.self) { style in
                        EntryStyleOption(
                            style: style,
                            isSelected: model.style == style
                        ) {
                            Task {
                                await model.choose(style)
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
        .sensoryFeedback(.selection, trigger: model.style)
        .task {
            await model.load()
        }
    }
}
