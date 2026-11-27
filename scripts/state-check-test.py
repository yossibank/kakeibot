#!/usr/bin/env python3
import os
import subprocess
import sys
import tempfile

CHECK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "state-check.py")
SWIFT = os.path.join("ios", "Packages", "KakeibotApp", "Sources", "FeatureModels", "Model.swift")
KOTLIN = os.path.join("android", "featuremodels", "src", "main", "Model.kt")
SWIFT_SOURCE = """
public final class EntryModel {
    @MainActor
    @Observable
    final class State: NoticesHolding {
        public var fields = Fields()
        public var presented = Presented()

        public internal(set) var outcome = ScreenOutcome<Outcome>()
        public private(set) var cursor = PeriodCursor()
        public internal(set) var editing: Target?
        @ObservationIgnored private var foreground = ForegroundReturn()

        public let notices: Notices
        public let task = ModelTask()
//MEMBER

        var isEmpty: Bool {
            fields.amount == 0
        }

        struct Fields {
            var amount = 0
            var walletId: Wallet.ID?
        }

        init() {
            notices = Notices()
        }
    }
}
"""
KOTLIN_SOURCE = """
class EntryModel {
    class State(
        date: LocalDate,
        wait: ScreenWait,
    ) {
        val notices = Notices(wait)
        val presented = Presented()

        var form: EntryForm by mutableStateOf(
            EntryForm(date = date),
        )
            private set

        var focus: FieldFocus by mutableStateOf(FieldFocus())
            private set

        private val foreground = ForegroundReturn()

        val round: Int
            get() = notices.round
//MEMBER

        data class Fields(
            val amount: Int = 0,
        )
    }
}
"""
SWIFT_CASES = [
    ("裸の Bool", "        public internal(set) var isSaving = false", "裸の値は State の直下に置かない"),
    ("裸の Optional の文字列", "        public internal(set) var memo: String?", "裸の値は State の直下に置かない"),
    ("裸の ID の配列", "        public internal(set) var ids: [Wallet.ID] = []", "裸の値は State の直下に置かない"),
    ("裸の日付", "        public let today: Date", "裸の値は State の直下に置かない"),
    ("直下のエラー", "        public let error = ErrorNotice()", "知らせは State の直下に置かず"),
    ("直下の取り消し", "        public let deletion: UndoNotice<Deletion>", "知らせは State の直下に置かず"),
    ("書ける var", "        var request = SwitchRequest()", "書けるのをモデルだけにする（private(set)"),
    ("外から書ける var", "        public var cursor = PeriodCursor()", "書けるのをモデルだけにする（private(set)"),
]
KOTLIN_CASES = [
    ("裸の Boolean", "        var isChosen = false\n            private set", "裸の値は State の直下に置かない"),
    ("裸の数", "        var count by mutableIntStateOf(0)\n            private set", "裸の値は State の直下に置かない"),
    ("裸の List", "        val ids: List<Long> = emptyList()", "裸の値は State の直下に置かない"),
    ("直下のエラー", "        val error = ErrorNotice()", "知らせは State の直下に置かず"),
    ("private set の無い var", "        var tabs: TabSelection by mutableStateOf(TabSelection())", "（private set）"),
]


def write(root, relative, text):
    path = os.path.join(root, relative)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as file:
        file.write(text)


def run(swift_member="", kotlin_member=""):
    with tempfile.TemporaryDirectory() as root:
        write(root, SWIFT, SWIFT_SOURCE.replace("//MEMBER", swift_member))
        write(root, KOTLIN, KOTLIN_SOURCE.replace("//MEMBER", kotlin_member))
        command = [sys.executable, "-I", CHECK, "--root", root]
        return subprocess.run(command, capture_output=True, text=True, check=False)


def main():
    failures = []
    result = run()

    if result.returncode != 0 or result.stdout.strip():
        failures.append(f"error: 正しい State: 出力が違う\n{result.stdout}{result.stderr}")

    cases = [(name, {"swift_member": member}, expected) for name, member, expected in SWIFT_CASES]
    cases += [(name, {"kotlin_member": member}, expected) for name, member, expected in KOTLIN_CASES]

    for name, members, expected in cases:
        result = run(**members)

        if result.returncode == 0 or expected not in result.stdout or len(result.stdout.strip().split("\n")) != 1:
            failures.append(f"error: {name}: 出力が違う\n{result.stdout}{result.stderr}")

    print("\n".join(failures))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
