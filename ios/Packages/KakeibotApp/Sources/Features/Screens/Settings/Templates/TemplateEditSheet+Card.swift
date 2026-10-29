import Core
import DesignSystem
import SwiftUI

extension TemplateEditSheet {
    var preview: some View {
        VStack(spacing: 16) {
            card

            Text("ホームでは、このカードで並びます")
                .textFont(.caption2)
                .tracking(1)
                .foregroundStyle(Palette.subtext)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background {
            EllipticalGradient(
                colors: [Palette.accent.opacity(.soft), .clear],
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            )
        }
    }

    var capsulePreview: some View {
        HStack(spacing: 8) {
            Text("入力シートでは")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)

            HStack(spacing: 8) {
                IconImage(categoryIcon, size: 12)
                    .foregroundStyle(Palette.accent)

                Text(previewName)
                    .foregroundStyle(Palette.text)

                Text(amountValue)
                    .displayFont(.caption)
                    .foregroundStyle(Palette.accentStrong)
            }
            .textFont(size: .caption)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .fixedSize()
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .frame(height: 30)
            .overlay {
                Capsule()
                    .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
            }
        }
        .frame(minHeight: 46)
    }

    var memoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("メモ", systemImage: "square.and.pencil")
                    .textFont(.caption)
                    .foregroundStyle(Palette.accent)

                Spacer()

                RingButton(systemImage: "checkmark", style: .prominent) {
                    closePanel()
                }
            }

            TextField(
                "メモ",
                text: $model.memo,
                prompt: Text("メモを書く").foregroundStyle(Palette.hint),
                axis: .vertical
            )
            .lineLimit(1...4)
            .textFont(.subheadline)
            .foregroundStyle(Palette.text)
            .tint(Palette.accent)
            .focused($focus, equals: .memo)
        }
        .padding(16)
        .floatingCard()
        .task {
            focus = .memo
        }
    }
}

extension TemplateEditSheet {
    var amountValue: String {
        model.amount.map { AmountText.text($0) } ?? "毎回入れる"
    }
}

private extension TemplateEditSheet {
    var card: some View {
        TemplateCard(icon: categoryIcon, detail: detail, size: .large) {
            HStack(spacing: 8) {
                TextField(
                    "名前",
                    text: $model.name,
                    prompt: Text("名前を入れる").foregroundStyle(Palette.hint)
                )
                .font(TemplateCardSize.large.nameFont(in: themeStyle))
                .foregroundStyle(Palette.accentStrong)
                .tint(Palette.accent)
                .submitLabel(.done)
                .focused($focus, equals: .name)
                .onSubmit {
                    focus = nil
                }

                Button {
                    focus = .name
                } label: {
                    EditBadge(size: 16)
                        .frame(width: 32, height: 32)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .opacity(nameBadgeOpacity)
            }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(nameLine)
                    .frame(height: 1)
            }
        } amount: {
            Button {
                open(.amount)
            } label: {
                HStack(spacing: 8) {
                    TemplateCardAmount(amount: model.amount, size: .large)

                    Spacer(minLength: 8)

                    EditBadge(size: 16)
                        .frame(width: 32, height: 32)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .glow(Palette.glow.opacity(.subtle), radius: 30)
        .background(alignment: .bottom) {
            Ellipse()
                .fill(Palette.shadow.opacity(0.55))
                .frame(width: 260, height: 22)
                .blur(radius: 14)
                .offset(y: 26)
        }
    }
}

private extension TemplateEditSheet {
    var categoryIcon: Icon? {
        model.selectedCategory.flatMap { model.icon(for: $0) }
    }

    var detail: String {
        let parts = [
            model.selectedCategory?.name,
            model.selectedTag?.name,
            model.selectedWallet?.name
        ]

        return parts.rowDetail ?? ""
    }

    var nameBadgeOpacity: Double {
        focus == .name ? 0 : 1
    }

    var nameLine: Color {
        if model.errorNotice.message != nil,
           model.name.isEmpty {
            Palette.rose
        } else if focus == .name {
            Palette.accent
        } else {
            Palette.accent.opacity(.medium)
        }
    }

    var previewName: String {
        model.name.isEmpty ? "名前" : model.name
    }
}
