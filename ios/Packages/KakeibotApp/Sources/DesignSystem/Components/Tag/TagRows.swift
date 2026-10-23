import SwiftUI

public struct TagRows<ID: Hashable & Sendable>: View {
    @State private var width: CGFloat = 0

    let tags: [TagLine<ID>.Item]
    let selection: Set<ID>
    let onSelect: (ID) -> Void

    public init(
        _ tags: [TagLine<ID>.Item],
        selection: Set<ID>,
        onSelect: @escaping (ID) -> Void
    ) {
        self.tags = tags
        self.selection = selection
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                TagLine(row, selection: selection, onSelect: onSelect)
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            self.width = width
        }
    }
}

private extension TagRows {
    var rows: [[TagLine<ID>.Item]] {
        guard width > 0 else {
            return [tags]
        }

        return tags.reduce(into: []) { rows, tag in
            let row = (rows.last ?? []) + [tag]
            let names = row.map(\.name)

            if let last = rows.indices.last,
               TagLine<ID>.fits(names, in: width) {
                rows[last] = row
            } else {
                rows.append([tag])
            }
        }
    }
}

#Preview {
    @Previewable @State var selection: Set = ["昼ごはん"]

    let names = [
        "朝ごはん", "昼ごはん", "夜ごはん", "おやつ", "飲み会",
        "コンビニ", "カフェ", "まとめ買い", "ランチ会"
    ]

    let tags = names.map { TagLine<String>.Item(id: $0, name: $0) }

    TagRows(tags, selection: selection) { id in
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }
    .padding()
    .background(Palette.background)
}
