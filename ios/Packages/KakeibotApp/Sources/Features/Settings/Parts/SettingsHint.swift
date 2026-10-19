import DesignSystem
import SwiftUI

struct SettingsHint: View {
    @State private var model: SettingsHintModel

    private let lines: [String]

    init(
        model: SettingsHintModel,
        lines: [String]
    ) {
        _model = State(initialValue: model)
        self.lines = lines
    }

    var body: some View {
        Group {
            if !model.isClosed {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(lines, id: \.self) { line in
                            Text(line)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Palette.mist)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        Task {
                            await model.close()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Palette.dusk)
                            .frame(width: 28, height: 28)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 12)
                .padding(.vertical, 6)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Palette.hairline, lineWidth: 1)
                }
                .transition(.opacity)
            }
        }
        .animation(.snappy, value: model.isClosed)
        .task {
            await model.load()
        }
    }
}

extension SettingsHint {
    static let moveAndHide = "長押しで並べ替え、下の枠に置くと非表示にできます"
}
