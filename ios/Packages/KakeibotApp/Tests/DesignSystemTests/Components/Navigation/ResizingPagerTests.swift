@testable import DesignSystem
import SwiftUI
import Testing
import UIKit

@MainActor
struct ResizingPagerTests {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 800))
    let frames = Frames()

    @Test
    func keepsAShortPageAtTheTop() async throws {
        let host = Host(frames: frames, rows: [1, 3])

        window.rootViewController = UIHostingController(rootView: host)
        window.makeKeyAndVisible()

        let laidOut = try await waitForPages()

        #expect(laidOut.row.minY == laidOut.pager.minY)
        #expect(laidOut.pager.height == laidOut.row.height)
    }
}

extension ResizingPagerTests {
    @Observable
    final class Frames {
        var values: [String: CGRect] = [:]
    }

    struct Page: Identifiable {
        let id: Int
        let rows: Int
    }

    struct Host: View {
        @State private var current = 0

        let frames: Frames
        let rows: [Int]

        var body: some View {
            ResizingPager(
                current: $current,
                pages: rows.enumerated().map { Page(id: $0.offset, rows: $0.element) },
                id: \.id,
                inset: 16
            ) { page in
                VStack(spacing: 8) {
                    ForEach(0..<page.rows, id: \.self) { index in
                        Color.orange
                            .frame(height: 80)
                            .onGeometryChange(for: CGRect.self) { proxy in
                                proxy.frame(in: .global)
                            } action: { value in
                                frames.values["\(page.id)-\(index)"] = value
                            }
                    }
                }
            }
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { value in
                frames.values["pager"] = value
            }
        }
    }
}

private extension ResizingPagerTests {
    func waitForPages() async throws -> (pager: CGRect, row: CGRect) {
        for _ in 0..<50 {
            if let pager = frames.values["pager"],
               let row = frames.values["0-0"],
               pager.height < 100 {
                return (pager, row)
            }

            try await Task.sleep(for: .milliseconds(20))
        }

        let pager = try #require(frames.values["pager"])
        let row = try #require(frames.values["0-0"])
        return (pager, row)
    }
}
