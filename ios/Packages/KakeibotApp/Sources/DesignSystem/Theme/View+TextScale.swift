import SwiftUI

public extension View {
    func sharesTextScale(id: some Equatable) -> some View {
        modifier(SharesTextScale(id: id))
    }

    func sharedTextScale() -> some View {
        modifier(SharedTextScale())
    }
}

private struct TextScaleReport: Equatable {
    var scale: Double
    var epoch: Int
}

private struct TextScaleKey: PreferenceKey {
    static let defaultValue = TextScaleReport(scale: 1, epoch: 0)

    static func reduce(
        value: inout TextScaleReport,
        nextValue: () -> TextScaleReport
    ) {
        let next = nextValue()

        value.scale = min(value.scale, next.scale)
        value.epoch = max(value.epoch, next.epoch)
    }
}

private struct SharesTextScale<ID: Equatable>: ViewModifier {
    @State private var scale = 1.0
    @State private var epoch = 0

    let id: ID

    func body(content: Content) -> some View {
        content
            .environment(\.groupTextScale, scale)
            .environment(\.textScaleEpoch, epoch)
            .onPreferenceChange(TextScaleKey.self) { report in
                scale = min(scale, report.scale)
            }
            .onChange(of: id) {
                scale = 1
                epoch += 1
            }
    }
}

private struct SharedTextScale: ViewModifier {
    @State private var available: CGFloat = .infinity
    @State private var needed: CGFloat = 0

    @Environment(\.groupTextScale) private var group
    @Environment(\.textScaleEpoch) private var epoch

    func body(content: Content) -> some View {
        let scale = TextScale.fitting(available: available, needed: needed)

        ProposedWidth {
            content
                .environment(\.sharedTextScale, group)
                .lineLimit(1)
                .truncationMode(.tail)

            Color.clear
                .frame(height: 0)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    available = width
                }
        }
        .background {
            content
                .environment(\.sharedTextScale, 1)
                .lineLimit(1)
                .fixedSize()
                .hidden()
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    needed = width
                }
        }
        .preference(
            key: TextScaleKey.self,
            value: TextScaleReport(scale: scale, epoch: epoch)
        )
    }
}

private struct ProposedWidth: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        subviews[0].sizeThatFits(proposal)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil }

        subviews[0].place(
            at: bounds.origin,
            proposal: proposal
        )

        subviews[1].place(
            at: bounds.origin,
            proposal: ProposedViewSize(
                width: width ?? bounds.width,
                height: 0
            )
        )
    }

    func explicitAlignment(
        of guide: VerticalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGFloat? {
        subviews[0].dimensions(in: proposal)[guide]
    }
}
