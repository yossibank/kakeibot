import SwiftUI

extension WidgetGuideStage {
    var control: some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 14) {
            GridRow {
                ForEach(Self.controls.prefix(4), id: \.self) { symbol in
                    controlButton(symbol)
                }
            }

            GridRow {
                ForEach(Self.controls.suffix(3), id: \.self) { symbol in
                    controlButton(symbol)
                }

                VStack(spacing: 4) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Self.night)
                        .frame(width: 62, height: 62)
                        .background(.white, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.5), lineWidth: 2)
                                .padding(-5)
                        }

                    Text("記録する")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

private extension WidgetGuideStage {
    func controlButton(_ symbol: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 62, height: 62)
                .background(.white.opacity(0.14), in: Circle())

            Text(" ")
                .font(.system(size: 11))
        }
    }
}
