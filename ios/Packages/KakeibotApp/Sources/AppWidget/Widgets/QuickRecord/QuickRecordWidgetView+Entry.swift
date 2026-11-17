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

extension QuickRecordWidgetView {
    @ViewBuilder
    var receiptLink: some View {
        if let url = PlannedNotification.Route.receipt.url {
            Link(destination: url) {
                Label("レシート", systemImage: "doc.text.viewfinder")
                    .textFont(size: .micro, weight: .medium)
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay {
                        Capsule()
                            .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 1)
                    }
            }
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
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Palette.backgroundTop)
                .frame(width: iconSize, height: iconSize)
                .background(Palette.accent, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("記録する")
                    .textFont(size: .caption, weight: .medium)
                    .foregroundStyle(Palette.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if isLarge {
                    Text("入力の画面を開きます")
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                Text("金額を入れる")
                    .textFont(size: .micro)
                    .foregroundStyle(Palette.hint)
            }

            Spacer(minLength: 0)
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
