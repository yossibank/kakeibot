import Core
import Foundation
import Testing

struct WalletDraftTests {
    @Test(arguments: try draftCases)
    func findsProblems(fixture: DraftCase) throws {
        let draft = try fixture.draft()
        #expect(draft.problems == fixture.problems)
    }

    @Test
    func makesWalletWithTrimmedName() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let draft = WalletDraft(
            kind: .card,
            name: " 楽天カード ",
            mark: .text("楽"),
            color: "#BF4040",
            initialBalance: -38000
        )

        let icon = try draft.newIcon(at: now)
        let wallet = try draft.newWallet(
            iconId: icon.id,
            sortOrder: 4,
            at: now
        )

        #expect(icon.text == "楽")
        #expect(wallet.name == "楽天カード")
        #expect(wallet.kind == .card)
        #expect(wallet.initialBalance == -38000)
        #expect(wallet.iconId == icon.id)
        #expect(wallet.sortOrder == 4)
    }

    @Test
    func keepsIdentityWhenApplied() throws {
        let created = Date(timeIntervalSince1970: 1_790_000_000)
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let icon = Icon(
            emoji: nil,
            text: nil,
            glyph: .bank,
            color: "#8DB0EA",
            createdAt: created,
            updatedAt: created
        )

        let wallet = Wallet(
            name: "銀行",
            kind: .bank,
            iconId: icon.id,
            initialBalance: 0,
            sortOrder: 1,
            createdAt: created,
            updatedAt: created
        )

        var draft = WalletDraft(wallet, icon: icon)
        draft.name = "ゆうちょ"
        draft.initialBalance = 120_000
        draft.mark = .emoji("📮")

        let updatedIcon = try draft.applied(to: icon, at: now)
        let updatedWallet = try draft.applied(to: wallet, at: now)

        #expect(updatedIcon.id == icon.id)
        #expect(updatedIcon.emoji == "📮")
        #expect(updatedIcon.glyph == nil)
        #expect(updatedWallet.id == wallet.id)
        #expect(updatedWallet.name == "ゆうちょ")
        #expect(updatedWallet.initialBalance == 120_000)
        #expect(updatedWallet.sortOrder == 1)
        #expect(updatedWallet.createdAt == created)
        #expect(updatedWallet.updatedAt == now)
    }
}

extension WalletDraftTests {
    struct DraftCase: Decodable, Sendable {
        let name: String
        let kind: Wallet.Kind
        let mark: FixtureMark
        let color: String
        let initialBalance: Int
        let problems: [DraftProblem]
    }
}

extension WalletDraftTests.DraftCase {
    func draft() throws -> WalletDraft {
        let mark = try mark.mark()

        return WalletDraft(
            kind: kind,
            name: name,
            mark: mark,
            color: color,
            initialBalance: initialBalance
        )
    }
}

private extension WalletDraftTests {
    static var draftCases: [DraftCase] {
        get throws {
            try Fixture.load("wallet/wallet-draft.json")
        }
    }
}
