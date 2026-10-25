import Core
import DesignSystem
import Store
import SwiftUI

public struct EntryStartView: View {
    @State private var model: EntryStartModel

    public init(model: EntryStartModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 20) {
            SettingsBackHeader("金額から入力")

            Text("＋を押したときに、最初に出す所を選べます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 12) {
                    preview
                        .padding(.vertical, 12)

                    SettingsOption(
                        "金額から",
                        note: "テンキーを開いて始めます",
                        systemImage: "number",
                        isSelected: model.startsWithAmount
                    ) {
                        choose(true)
                    }

                    SettingsOption(
                        "カテゴリから",
                        note: "カテゴリを選んでから金額を入れます",
                        systemImage: "square.grid.2x2",
                        isSelected: !model.startsWithAmount
                    ) {
                        choose(false)
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
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.snappy, value: model.startsWithAmount)
        .transaction(value: model.isLoaded) { transaction in
            transaction.disablesAnimations = true
        }
        .sensoryFeedback(.selection, trigger: model.startsWithAmount)
        .task {
            await model.load()
        }
    }
}

private extension EntryStartView {
    var preview: some View {
        ZStack {
            if model.isLoaded {
                EntrySheet(
                    model: EntryModel(
                        database: model.database,
                        date: model.today
                    )
                )
                .id(model.startsWithAmount)
                .transition(.opacity)
            }
        }
        .frame(width: Self.screenSize.width, height: Self.screenSize.height)
        .background(Palette.background)
        .allowsHitTesting(false)
        .scaleEffect(Self.scale)
        .frame(
            width: Self.screenSize.width * Self.scale,
            height: Self.screenSize.height * Self.scale
        )
        .clipShape(Self.screenShape)
        .overlay {
            Self.screenShape
                .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
        }
        .shadow(color: Palette.shadow.opacity(.muted), radius: 16, y: 6)
    }
}

private extension EntryStartView {
    static let screenSize = CGSize(width: 393, height: 780)
    static let scale: CGFloat = 0.5
    static let screenShape = RoundedRectangle(cornerRadius: 26)

    func choose(_ starts: Bool) {
        Task {
            await model.choose(starts)
        }
    }
}
