import Core
import DesignSystem
import SwiftUI

struct HomeCustomizeCard: View {
    @Environment(\.themeStyle) private var themeStyle

    let model: SetupModel
    let appIcon: AppIconListModel
    let onOpen: (SetupItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HomeCardHeader(title: "自分好みにカスタマイズ") {
                Task {
                    await model.closeCustomizeCard()
                }
            }

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(SetupItem.customize) { item in
                        Button {
                            open(item)
                        } label: {
                            tile(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 14, for: .scrollContent)
            .contentMargins(.vertical, 6, for: .scrollContent)
            .scrollClipDisabled()
            .mask {
                Rectangle()
                    .padding(.vertical, -Self.shadowRoom)
            }
            .padding(.horizontal, -16)
            .padding(.vertical, -8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .card()
    }
}

private extension HomeCustomizeCard {
    func tile(_ item: SetupItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: item.systemImage)
                .sansFont(.body, weight: .light)
                .foregroundStyle(Palette.accent)

            Spacer(minLength: 8)

            Text(item.title)
                .textFont(.caption)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(Self.textScale)

            Text(value(for: item))
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(Self.textScale)
                .contentTransition(.opacity)
        }
        .padding(12)
        .frame(width: Self.tileSize.width, height: Self.tileSize.height, alignment: .leading)
        .templateCardFace(cornerRadius: 18, shadowRadius: 12)
        .contentShape(.rect)
    }
}

private extension HomeCustomizeCard {
    static let tileSize = CGSize(width: 116, height: 96)
    static let textScale: CGFloat = 0.7
    static let shadowRoom: CGFloat = 32

    func value(for item: SetupItem) -> String {
        switch item {
        case .launchScreen: model.launchScreen.title
        case .startsWithAmount: model.startsWithAmountTitle
        case .theme: model.themeTitle
        case .appIcon: appIcon.current.title
        case .themeStyle: themeStyle.shortTitle
        default: ""
        }
    }

    func open(_ item: SetupItem) {
        guard item.isToggle else {
            onOpen(item)

            return
        }

        Task {
            await model.setStartsWithAmount(!model.startsWithAmount)
        }
    }
}
