import Core
import SwiftUI

struct BillPager<Page: View>: View {
    @Binding var current: Int

    @State private var position: Int?
    @State private var heights: [Int: CGFloat] = [:]
    @State private var progress: CGFloat = 0

    let pages: [BillPage]
    let inset: CGFloat
    let page: (BillPage) -> Page

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(pages.enumerated()), id: \.element.month) { index, item in
                    page(item)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, inset)
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.height
                        } action: { height in
                            heights[index] = height
                        }
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $position)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            Self.progress(of: geometry)
        } action: { _, value in
            progress = value
        }
        .frame(height: height)
        .padding(.horizontal, -inset)
        .onAppear {
            position = current
        }
        .onChange(of: position) { _, value in
            if let value,
               value != current {
                current = value
            }
        }
        .onChange(of: current) { _, value in
            guard value != position else {
                return
            }

            withAnimation(.smooth) {
                position = value
            }
        }
    }
}

private extension BillPager {
    var height: CGFloat? {
        guard !heights.isEmpty else {
            return nil
        }

        let last = CGFloat(max(pages.count - 1, 0))
        let place = min(max(progress, 0), last)
        let lower = Int(place.rounded(.down))
        let upper = min(lower + 1, pages.count - 1)
        let from = heights[lower] ?? heights[upper] ?? 0
        let to = heights[upper] ?? from

        return from + (to - from) * (place - CGFloat(lower))
    }

    static func progress(of geometry: ScrollGeometry) -> CGFloat {
        let width = geometry.containerSize.width
        return width > 0 ? geometry.contentOffset.x / width : 0
    }
}
