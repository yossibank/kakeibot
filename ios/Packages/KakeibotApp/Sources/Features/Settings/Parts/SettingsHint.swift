import DesignSystem
import SwiftUI

struct SettingsHint: View {
    private let lines: [String]

    init(_ lines: String...) {
        self.lines = lines
    }

    init(lines: [String]) {
        self.lines = lines
    }

    var body: some View {
        VStack(spacing: 2) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .font(.caption)
        .foregroundStyle(Palette.mist)
        .frame(maxWidth: .infinity)
    }
}

extension SettingsHint {
    static let moveAndHide = "長押しで並べ替え、下の枠に置くと非表示にできます"
}
