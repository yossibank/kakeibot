import Core
import DesignSystem
import SwiftUI

struct RecordsStampSheet: View {
    @State private var isAddingStamp = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let date: LocalDate
    let choices: [Icon]
    let current: Icon?
    let editModel: () -> StampEditModel
    let onPick: (Icon) -> Void
    let onRemove: () -> Void

    var body: some View {
        FittedSheet {
            VStack(spacing: 18) {
                header

                if choices.isEmpty {
                    RecordsSheetEmpty(
                        systemImage: "seal",
                        title: "スタンプがまだありません",
                        message: "スタンプを作ると、ここから押せます",
                        actionTitle: "スタンプを作る"
                    ) {
                        isAddingStamp = true
                    }
                } else {
                    LazyVGrid(columns: Self.columns, spacing: 12) {
                        ForEach(choices, id: \.id) { icon in
                            choice(icon)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if current != nil {
                    Button {
                        onRemove()
                        dismiss()
                    } label: {
                        Label("スタンプを外す", systemImage: "xmark.circle")
                            .textFont(.subheadline)
                            .foregroundStyle(Palette.rose)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $isAddingStamp) {
            StampEditSheet(model: editModel())
        }
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
                .displayFont(.body)
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
                    RoundedRectangle(cornerRadius: corner.radius(20))
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
