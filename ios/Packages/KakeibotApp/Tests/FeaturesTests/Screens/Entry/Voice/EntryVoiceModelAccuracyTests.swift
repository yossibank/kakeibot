import Core
@testable import Features
import Foundation
import FoundationModels
import Testing

@MainActor
struct EntryVoiceModelAccuracyTests {
    @Test(.enabled(if: isModelUsable))
    func choosesCategoriesAndWalletsWell() async throws {
        guard #available(iOS 26.0, *) else {
            return
        }

        let fixture = try Self.fixture
        var categoryHits = 0
        var categoryTotal = 0
        var walletHits = 0
        var walletTotal = 0
        var misses: [String] = []

        for spoken in fixture.cases where spoken.modelCategory != nil || spoken.modelWallet != nil {
            let choice = await EntryVoiceModel.choose(
                in: spoken.text,
                categories: fixture.categories,
                wallets: fixture.wallets,
                examples: []
            )

            if let expected = spoken.modelCategory {
                let chosen = choice?.categoryIndex.map { fixture.categories[$0] }
                categoryTotal += 1

                if let chosen, expected.contains(chosen) {
                    categoryHits += 1
                } else {
                    misses.append("\(spoken.text)：カテゴリ \(chosen ?? "なし")")
                }
            }

            if let expected = spoken.modelWallet {
                let chosen = choice?.walletIndex.map { fixture.wallets[$0] }
                walletTotal += 1

                if let chosen, expected.contains(chosen) {
                    walletHits += 1
                } else {
                    misses.append("\(spoken.text)：口座 \(chosen ?? "なし")")
                }
            }
        }

        let categoryRate = Double(categoryHits) / Double(max(categoryTotal, 1))
        let walletRate = Double(walletHits) / Double(max(walletTotal, 1))
        let report = [
            "カテゴリ \(categoryHits)/\(categoryTotal)",
            "口座 \(walletHits)/\(walletTotal)"
        ] + misses

        Attachment.record(report.joined(separator: "\n"), named: "voice-model-accuracy.txt")

        #expect(categoryRate >= Self.minimumRate, "\(report.joined(separator: "\n"))")
        #expect(walletRate >= Self.minimumRate, "\(report.joined(separator: "\n"))")
    }
}

private extension EntryVoiceModelAccuracyTests {
    struct Fixture: Decodable {
        let categories: [String]
        let wallets: [String]
        let cases: [SpokenCase]
    }

    struct SpokenCase: Decodable {
        let text: String
        let modelCategory: [String]?
        let modelWallet: [String]?
    }

    static let minimumRate = 0.8

    static let fixtureURL = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "../../../../../../../../spec/fixtures/voice/voice-reading.json")
        .standardized

    static var fixture: Fixture {
        get throws {
            try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: fixtureURL))
        }
    }
}

private var isModelUsable: Bool {
    guard #available(iOS 26.0, *) else {
        return false
    }

    let model = SystemLanguageModel.default
    return model.isAvailable && model.supportsLocale(Locale(identifier: "ja_JP"))
}
