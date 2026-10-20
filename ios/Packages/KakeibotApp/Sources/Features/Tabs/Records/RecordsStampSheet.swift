import Core
import DesignSystem
import SwiftUI

struct RecordsStampSheet: View {
    @Environment(\.dismiss) private var dismiss

    let date: LocalDate
    let choices: [Icon]
    let current: Icon?
    let onPick: (Icon) -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            header

            if choices.isEmpty {
                Text("設定の「スタンプ」で作ると、ここから押せます")
                    .font(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    LazyVGrid(columns: Self.columns, spacing: 12) {
                        ForEach(choices, id: \.id) { icon in
                            choice(icon)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
            }

            if current != nil {
                Button {
                    onRemove()
                    dismiss()
                } label: {
                    Label("スタンプを外す", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(Palette.rose)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .presentationDetents([.medium])
    }
}

private extension RecordsStampSheet {
    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                dismiss()
            }

            Spacer()

            Text("\(date.month)/\(date.day) のスタンプ")
                .font(.serif(.body))
                .tracking(2)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    func choice(_ icon: Icon) -> some View {
        let isCurrent = current?.id == icon.id
        let ring = isCurrent ? Palette.accent : Color.clear

        return Button {
            onPick(icon)
            dismiss()
        } label: {
            IconBadge(icon, size: 52)
                .padding(4)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ring, lineWidth: 1.5)
                }
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension RecordsStampSheet {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 5
    )
}
