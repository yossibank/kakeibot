#!/usr/bin/env python3
import os
import subprocess
import sys
import tempfile

CHECK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "state-check.py")
SWIFT = os.path.join("ios", "Packages", "KakeibotApp", "Sources", "FeatureModels", "Model.swift")
KOTLIN = os.path.join("android", "featuremodels", "src", "main", "Model.kt")
APP_SWIFT = os.path.join("ios", "Packages", "KakeibotApp", "Sources", "AppFeature", "AppModel.swift")
APP_KOTLIN = os.path.join(
    "android", "app", "src", "main", "kotlin", "com", "yossibank", "kakeibot", "appfeature", "AppModel.kt"
)
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

    @MainActor
    @Observable
    final class Input {
        public internal(set) var isAvailable = false
        public internal(set) var isFetching = false
        public internal(set) var cardClosed: Bool?
        public let silenceDuration: TimeInterval

        @ObservationIgnored var latest: AssetsSummary.Input
        @ObservationIgnored var permission = NotificationPermission.allowed
//INPUT

        var isEmpty: Bool {
            latest.isEmpty
        }
    }

    final class Runtime {
        var silenceTask: Task<Void, Never>?
        var isStarting = false
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

    class Input(
        val isAvailable: Boolean,
        today: LocalDate,
    ) {
        var today: LocalDate by mutableStateOf(today)
            internal set

        var isHidden: Boolean by mutableStateOf(false)
            internal set
//INPUT
    }

    private class Runtime {
        var silenceJob: Job? = null
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
SWIFT_INPUT_CASES = [
    ("Input の Task", "        @ObservationIgnored var silenceTask: Task<Void, Never>?", "動いている Task と Job は Input に置かない"),
    ("Input の実行中の印", "        @ObservationIgnored var isRefreshing = false", "実行中の印と、走らせ直すための印は Input に置かない"),
    ("Input の走らせ直す印", "        var needsRefresh: Bool = false", "実行中の印と、走らせ直すための印は Input に置かない"),
    ("Input の見ない Bool", "        @ObservationIgnored\n        var isReady = false", "実行中の印と、走らせ直すための印は Input に置かない"),
]
KOTLIN_INPUT_CASES = [
    ("Input の Job", "        var job: Job? = null", "動いている Task と Job は Input に置かない"),
    ("Input の実行中の印", "        var isStarting: Boolean by mutableStateOf(false)\n            internal set", "実行中の印と、走らせ直すための印は Input に置かない"),
]


def write(root, relative, text):
    path = os.path.join(root, relative)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as file:
        file.write(text)


def run(swift_member="", kotlin_member="", swift_input="", kotlin_input="", app=False):
    with tempfile.TemporaryDirectory() as root:
        for swift, kotlin, chosen in ((SWIFT, KOTLIN, not app), (APP_SWIFT, APP_KOTLIN, app)):
            swift_text = SWIFT_SOURCE.replace("//MEMBER", swift_member if chosen else "")
            kotlin_text = KOTLIN_SOURCE.replace("//MEMBER", kotlin_member if chosen else "")
            write(root, swift, swift_text.replace("//INPUT", swift_input if chosen else ""))
            write(root, kotlin, kotlin_text.replace("//INPUT", kotlin_input if chosen else ""))
        command = [sys.executable, "-I", CHECK, "--root", root]
        return subprocess.run(command, capture_output=True, text=True, check=False)


def main():
    failures = []
    result = run()

    if result.returncode != 0 or result.stdout.strip():
        failures.append(f"error: 正しい State と Input: 出力が違う\n{result.stdout}{result.stderr}")

    cases = [(name, {"swift_member": member}, expected) for name, member, expected in SWIFT_CASES]
    cases += [(name, {"kotlin_member": member}, expected) for name, member, expected in KOTLIN_CASES]
    cases += [(name, {"swift_input": member}, expected) for name, member, expected in SWIFT_INPUT_CASES]
    cases += [(name, {"kotlin_input": member}, expected) for name, member, expected in KOTLIN_INPUT_CASES]
    cases += [
        (f"アプリの {name}", {"swift_member": member, "app": True}, expected)
        for name, member, expected in SWIFT_CASES[:1]
    ]
    cases += [
        (f"アプリの {name}", {"kotlin_member": member, "app": True}, expected)
        for name, member, expected in KOTLIN_CASES[:1]
    ]

    for name, members, expected in cases:
        result = run(**members)

        if result.returncode == 0 or expected not in result.stdout or len(result.stdout.strip().split("\n")) != 1:
            failures.append(f"error: {name}: 出力が違う\n{result.stdout}{result.stderr}")

    print("\n".join(failures))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
