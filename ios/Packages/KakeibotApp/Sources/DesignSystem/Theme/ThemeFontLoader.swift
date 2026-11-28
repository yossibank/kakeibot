import Core
import CoreText
import Observation
import os

@MainActor
@Observable
public final class ThemeFontLoader {
    public static let shared = ThemeFontLoader()

    public private(set) var phases: [ThemeFont: Phase] = [:]

    private init() {}
}

public extension ThemeFontLoader {
    enum Phase: Sendable {
        case checking
        case notLoaded
        case loading
        case ready
    }
}

private extension ThemeFontLoader {
    enum Source {
        case network
        case device
    }
}

public extension ThemeFontLoader {
    func phase(of font: ThemeFont) -> Phase {
        guard font.downloadName != nil else {
            return .ready
        }

        return phases[font] ?? .notLoaded
    }

    func shownFont(for font: ThemeFont) -> ThemeFont {
        phase(of: font) == .ready ? font : font.fallback
    }

    func load(_ font: ThemeFont) {
        guard
            let name = font.downloadName,
            phases[font] != .loading,
            phases[font] != .ready
        else {
            return
        }

        if Self.isInstalled(name) {
            phases[font] = .ready
            return
        }

        phases[font] = .loading

        Task {
            let isReady = await Self.match(name, source: .network)
            phases[font] = isReady ? .ready : .notLoaded
        }
    }

    func restore(_ fonts: [ThemeFont]) {
        for font in fonts {
            guard
                let name = font.downloadName,
                phases[font] == nil
            else {
                continue
            }

            phases[font] = .checking

            Task {
                let isReady = await Self.match(name, source: .device)

                if phases[font] == .checking {
                    phases[font] = isReady ? .ready : .notLoaded
                }
            }
        }
    }
}

private extension ThemeFontLoader {
    nonisolated static func isInstalled(_ name: String) -> Bool {
        let font = CTFontCreateWithName(name as CFString, 12, nil)
        return CTFontCopyPostScriptName(font) as String == name
    }

    nonisolated static func match(
        _ name: String,
        source: Source
    ) async -> Bool {
        let descriptor = CTFontDescriptorCreateWithNameAndSize(name as CFString, 0)
        let descriptors = [descriptor] as CFArray
        let isDone = OSAllocatedUnfairLock(initialState: false)

        return await withCheckedContinuation { continuation in
            let started = CTFontDescriptorMatchFontDescriptorsWithProgressHandler(
                descriptors,
                nil
            ) { state, _ in
                guard let result = result(of: state, name: name, source: source) else {
                    return true
                }

                let isFirst = isDone.withLock { done in
                    defer {
                        done = true
                    }

                    return !done
                }

                if isFirst {
                    continuation.resume(returning: result)
                }

                return result
            }

            if !started {
                continuation.resume(returning: false)
            }
        }
    }

    nonisolated static func result(
        of state: CTFontDescriptorMatchingState,
        name: String,
        source: Source
    ) -> Bool? {
        switch state {
        case .willBeginDownloading: source == .network ? nil : false
        case .didFinish: isInstalled(name)
        default: nil
        }
    }
}

public extension ThemeFont {
    var downloadName: String? {
        switch self {
        case .mincho, .gothic, .rounded, .dot, .pop: nil
        case .handwriting: "Klee-Medium"
        case .textbook: "YuKyo-Medium"
        case .boldMincho: "ToppanBunkyuMidashiMinchoStdN-ExtraBold"
        case .boldGothic: "ToppanBunkyuMidashiGothicStdN-ExtraBold"
        case .kanaMincho: "YuMin_36pKn-Medium"
        }
    }
}

private extension ThemeFont {
    var fallback: ThemeFont {
        switch self {
        case .boldGothic: .gothic
        default: .mincho
        }
    }
}
