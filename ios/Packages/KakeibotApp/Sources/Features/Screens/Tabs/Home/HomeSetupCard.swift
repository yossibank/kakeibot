import DesignSystem
import SwiftUI

struct HomeSetupCard: View {
    let model: SetupModel
    let onOpen: (SetupItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("あと \(model.cardItems.count) つで準備がそろいます")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.accentStrong)
                    .contentTransition(.numericText())

                Spacer()

                Button {
                    Task {
                        await model.closeCard()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Palette.subtext)
                        .frame(width: 24, height: 24)
                        .background(Palette.line, in: Circle())
                        .frame(width: 32, height: 32)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)

            SetupList(model.cardItems, model: model, onOpen: onOpen)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
        .animation(.snappy, value: model.cardItems)
    }
}
