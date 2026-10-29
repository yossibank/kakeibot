import DesignSystem
import SwiftUI

struct ThemeStyleChoices<Option: Hashable & Sendable, Sample: View>: View {
    @Environment(\.themeStyle.corner) private var corner

    let title: String
    let options: [Option]
    let selection: Option
    let columns: Int
    let label: (Option) -> String
    @ViewBuilder let sample: (Option) -> Sample
    let choose: (Option) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ThemeStyleRowTitle(title)

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(options, id: \.self) { option in
                    tile(option)
                }
            }
        }
    }
}

private extension ThemeStyleChoices {
    func tile(_ option: Option) -> some View {
        let isSelected = option == selection
        let ring = isSelected ? Palette.accent : Palette.line
        let titleColor = isSelected ? Palette.accentStrong : Palette.subtext
        let ringWidth: CGFloat = isSelected ? 1.5 : 1
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))

        return Button {
            Task {
                await choose(option)
            }
        } label: {
            VStack(spacing: 8) {
                sample(option)

                Text(label(option))
                    .textFont(.caption2)
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.horizontal, 8)
            .background(Palette.panel, in: shape)
            .overlay {
                shape
                    .stroke(ring, lineWidth: ringWidth)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}

private extension ThemeStyleChoices {
    var gridColumns: [GridItem] {
        let count = min(options.count, columns)

        return Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: count
        )
    }
}

struct ThemeStyleRowTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        SectionTitle(title)
            .padding(.leading, 8)
    }
}

struct ThemeStyleSwitch: View {
    @Environment(\.themeStyle.corner) private var corner

    let title: String
    let detail: String
    let isOn: Bool
    let change: (Bool) async -> Void

    var body: some View {
        Toggle(isOn: binding) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)

                Text(detail)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
            }
        }
        .tint(Palette.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Palette.panel, in: .rect(cornerRadius: corner.radius(16)))
    }
}

private extension ThemeStyleSwitch {
    var binding: Binding<Bool> {
        Binding {
            isOn
        } set: { value in
            Task {
                await change(value)
            }
        }
    }
}
