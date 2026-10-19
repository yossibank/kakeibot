import Observation
import SwiftUI

@MainActor
@Observable
final class SettingsAutoScroll {
    var position = ScrollPosition()

    fileprivate(set) var offset: CGFloat = 0
    fileprivate(set) var maxOffset: CGFloat = 0
    fileprivate(set) var viewport: CGRect = .zero

    private var speed: CGFloat = 0
    private var onStep: ((CGFloat) -> Void)?
    private var task: Task<Void, Never>?
}

extension SettingsAutoScroll {
    func follow(
        y: CGFloat,
        bottom: CGFloat?,
        onStep: @escaping (CGFloat) -> Void
    ) {
        let lower = min(bottom ?? viewport.maxY, viewport.maxY)
        speed = Self.speed(y: y, top: viewport.minY, bottom: lower)
        self.onStep = onStep

        guard
            speed != 0,
            task == nil
        else {
            return
        }

        task = Task {
            await run()
        }
    }

    func stop() {
        speed = 0
        onStep = nil
        task?.cancel()
        task = nil
    }
}

private extension SettingsAutoScroll {
    static let topBand: CGFloat = 80
    static let bottomBand: CGFloat = 140
    static let maxSpeed: CGFloat = 20
    static let fullSpeedDepth: CGFloat = 2 / 3

    static func speed(
        y: CGFloat,
        top: CGFloat,
        bottom: CGFloat
    ) -> CGFloat {
        if y < top + topBand {
            let depth = (top + topBand - y) / topBand
            return -maxSpeed * ramp(depth)
        }

        if y > bottom - bottomBand, y < bottom {
            let depth = (y - (bottom - bottomBand)) / bottomBand
            return maxSpeed * ramp(depth)
        }

        return 0
    }

    static func ramp(_ depth: CGFloat) -> CGFloat {
        min(depth / fullSpeedDepth, 1)
    }

    func run() async {
        while !Task.isCancelled, speed != 0 {
            let target = min(max(offset + speed, 0), maxOffset)
            let delta = target - offset

            if delta != 0 {
                offset = target
                position.scrollTo(y: target)
                onStep?(delta)
            }

            try? await Task.sleep(for: .milliseconds(16))
        }

        task = nil
    }
}

extension View {
    func settingsAutoScroll(_ autoScroll: SettingsAutoScroll) -> some View {
        modifier(SettingsAutoScrollModifier(autoScroll: autoScroll))
    }
}

private struct SettingsAutoScrollModifier: ViewModifier {
    struct Metrics: Equatable {
        let offset: CGFloat
        let maxOffset: CGFloat
    }

    @Bindable var autoScroll: SettingsAutoScroll

    func body(content: Content) -> some View {
        content
            .scrollPosition($autoScroll.position)
            .onScrollGeometryChange(for: Metrics.self) { geometry in
                let range = geometry.contentSize.height
                    - geometry.containerSize.height

                return Metrics(
                    offset: geometry.contentOffset.y,
                    maxOffset: max(range, 0)
                )
            } action: { _, metrics in
                autoScroll.offset = metrics.offset
                autoScroll.maxOffset = metrics.maxOffset
            }
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                autoScroll.viewport = frame
            }
    }
}
