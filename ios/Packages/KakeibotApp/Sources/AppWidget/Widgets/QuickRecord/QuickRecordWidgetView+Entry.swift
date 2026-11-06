import Core
import DesignSystem
import SwiftUI
import WidgetKit

extension QuickRecordWidgetView {
    var emptyTemplateGuide: some View {
        VStack(spacing: 8) {
            Text("よく使う支出を 1 回で記録できます")
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)

            Label("テンプレートを作る", systemImage: "plus")
                .textFont(size: .caption, weight: .semibold)
                .foregroundStyle(Palette.backgroundTop)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Palette.accent, in: Capsule())
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(QuickRecordEntryOutline())
    }

    func entryTileLink(padding: CGFloat) -> some View {
        entryLink {
            entryTileFace(padding: padding)
        }
    }
}

private extension QuickRecordWidgetView {
    var entryURL: URL? {
        let today = LocalDate(entry.date, in: .current)
        return PlannedNotification.Route.entry(today).url
    }

    @ViewBuilder
    func entryLink(@ViewBuilder content: () -> some View) -> some View {
        if let url = entryURL {
            Link(destination: url) {
                content()
            }
        } else {
            content()
        }
    }

    func entryTileFace(padding: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Palette.backgroundTop)
                    .frame(width: Self.badgeSize, height: Self.badgeSize)
                    .background(Palette.accent, in: Circle())

                Text("記録する")
                    .textFont(size: .caption, weight: .medium)
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            if isLarge {
                Text("入力の画面を開きます")
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.leading, Self.badgeSize + 4)
            }

            Spacer(minLength: 0)

            Text("金額を入れる")
                .textFont(size: .micro)
                .foregroundStyle(Palette.hint)
                .frame(minHeight: Self.markSize)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .modifier(QuickRecordEntryOutline())
    }
}

private struct QuickRecordEntryOutline: ViewModifier {
    @Environment(\.themeStyle.corner) private var corner

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(QuickRecordWidgetView.tileRadius))

        return content
            .background(Palette.accent.opacity(.subtle), in: shape)
            .overlay {
                shape
                    .strokeBorder(Palette.accent.opacity(.medium), style: .dashed)
            }
            .contentShape(shape)
    }
}
