import DesignSystem
import SwiftUI

struct SettingsNote: View {
    let text: String
    let kind: Kind

    init(_ text: String, kind: Kind = .info) {
        self.text = text
        self.kind = kind
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: systemImage)

            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .textFont(.caption)
        .foregroundStyle(color)
        .padding(.leading, 8)
    }
}

extension SettingsNote {
    enum Kind {
        case info
        case caution
    }
}

private extension SettingsNote {
    var systemImage: String {
        switch kind {
        case .info: "info.circle"
        case .caution: "exclamationmark.triangle"
        }
    }

    var color: Color {
        switch kind {
        case .info: Palette.subtext
        case .caution: Palette.rose
        }
    }
}
