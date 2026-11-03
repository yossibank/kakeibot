import Core
import DesignSystem
import SwiftUI

struct SettingsIntroCard: View {
    private let systemImage: String
    private let headline: (String, String)
    private let notes: [Note]
    private let flag: SettingsScreenFlag?

    init(
        systemImage: String,
        headline: (String, String),
        notes: [Note] = [],
        flag: SettingsScreenFlag? = nil
    ) {
        self.systemImage = systemImage
        self.headline = headline
        self.notes = notes
        self.flag = flag
    }

    var body: some View {
        if let flag {
            VStack(spacing: 0) {
                if !flag.isOn {
                    card
                        .transition(Self.transition)
                }
            }
            .task {
                await flag.load()
            }
        } else {
            card
        }
    }
}

extension SettingsIntroCard {
    struct Note {
        let systemImage: String
        let text: String

        init(
            _ systemImage: String,
            _ text: String
        ) {
            self.systemImage = systemImage
            self.text = text
        }
    }
}

extension SettingsIntroCard.Note {
    static let arrange = Self("hand.draw", "長押しで並べ替え・非表示にできます")
    static let swipeDelete = Self("hand.point.left", "横に払うと、非表示と削除を選べます")
}

private extension SettingsIntroCard {
    var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .sansFont(.body, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .stroke(Palette.outline, lineWidth: 0.8)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(headline.0)
                    Text(headline.1)
                }
                .displayFont(.body, weight: .medium)
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

                if let flag {
                    RingButton(
                        systemImage: "xmark",
                        size: .small
                    ) {
                        withAnimation(.snappy) {
                            _ = flag.set(true)
                        }
                    }
                }
            }

            if !notes.isEmpty {
                Hairline()

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(notes) { note in
                        row(note)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    func row(_ note: Note) -> some View {
        HStack(spacing: 12) {
            Image(systemName: note.systemImage)
                .sansFont(.caption, weight: .medium)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(note.text)
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private extension SettingsIntroCard {
    static var transition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
    }
}

extension SettingsIntroCard.Note: Identifiable {
    var id: String {
        systemImage + text
    }
}

#Preview {
    SettingsIntroCard(
        systemImage: "building.columns",
        headline: ("お金を置く所ごとに", "残高を分けて数えます"),
        notes: [.arrange, .swipeDelete]
    )
    .padding()
    .background(Palette.background)
}
